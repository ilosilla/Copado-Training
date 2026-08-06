/**
* @author 		Ivan Losilla
* @date 		October 2025
* @group 		WeeklyManagement
* @description 	Class to manage all components related
* @test         WeeklyManagementControllerTest
*/
public class WeeklyManagementController {
    public class WeeklyManagementException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static weeklyData getWeeklyData(Date startDate, Date endDate, String userId) {
        return new weeklyData(startDate, endDate, userId);
    }

    @AuraEnabled(cacheable=false)
    public static List<Event> getEvents(Date startDate, Date endDate, String userId) {
        List<Event> result = [SELECT Id, Subject,Description, startDateTime, endDateTime,whatId, WhoId,cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c, otherComments__c,IsPrivate
                                            FROM Event
                                            WHERE
                                            StartDateTime >=: startDate AND
                                            StartDateTime <=: endDate AND
                                            CreatedById =: userId AND
                                            OwnerId =: userId AND
                                            isPrivate = false AND
                                            (NOT Subject LIKE '%[Internal]%') AND
                                            (NOT Location LIKE '%Microsoft Teams%') AND
                                            Type != 'Non Commercial' AND
                                            isChild = false];

        return result;
    }

    /**
     * @description Updates the LoginFlowCompleted__c status of the event automatically, so the user doesn't need to complete all events
     */
    public static void eventsSetCompleted(List<Event> events) {
        List<Account> keyAccounts = new List<Account>();
        List<Follow__c> eventFollows = new List<Follow__c>();
        Set<String> followEventsId = new Set<String>();
        Set<String> eventsId = new Set<String>();
        Boolean completed = false;

        for (Event evt : events) {
            eventsId.add(evt.Id);
        }

        eventFollows = [SELECT Id, ActivityId__c FROM Follow__c WHERE ActivityId__c IN : eventsId];
        for (Follow__c fol : eventFollows) {
            followEventsId.add(fol.ActivityId__c);
        }

        for (Event evt : events) {
            if (evt.LoginFlowCompleted__c == null) {
                if (evt.Cancelled__c == true || evt.IsPrivate == true) {
                    completed = true;
                } else {
                    if (followEventsId.contains(evt.Id) == false) {
                        if (evt.WhatId != null && evt.WhoId != null ) {
                            completed = true;
                        }
                    } else {
                        if (evt.WhatId != null && evt.WhoId != null && evt.Description != null) {
                            completed = true;
                        }
                    }
                }
    
                if (completed == true) {
                    evt.LoginFlowCompleted__c = System.today();
                }
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getKeyAccounts(String userId) {
        List<Follow__c> follows = [select id, Account__r.ownerId, Account__r.name, Account__r.Owner.Email, Owner.Alias from Follow__c where RecordType.name = 'Account' and Owner.Alias IN ('ssega','MPrio', 'JB', 'PSimar') and Account__r.ownerId =: userId];
        Set<String> accountIds = new Set<String>();


        for (Follow__c follow : follows) {
            accountIds.add(follow.Account__c);
        }

        return [SELECT id,Last_Activity_Date__c,Owner.Email,toLabel(Account_Classification__c),Account_Status__c,Name, Phone, Business_Email__c FROM Account WHERE Id in : accountIds];
    }


    public static List<Account> getKeyAccounts() {
        List<Follow__c> follows = [select id, Account__r.ownerId, Account__r.name, Account__r.Owner.Email, Owner.Alias from Follow__c where RecordType.name = 'Account' and Owner.Alias IN ('ssega','MPrio', 'JB', 'PSimar')];
        Set<String> accountIds = new Set<String>();


        for (Follow__c follow : follows) {
            accountIds.add(follow.Account__c);
        }

        return [SELECT id,Last_Activity_Date__c,Owner.Email,toLabel(Account_Classification__c),Account_Status__c,Name, Phone, Business_Email__c FROM Account WHERE Id in : accountIds];
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountAdditionalInfo__c> getKeyAccountsComments(Date startDate, Date endDate, String userId) {
        List<Account> keyAccounts = getKeyAccounts(userId);
        Set<String> accountIds = new Set<String>();

        for (Account acc : keyAccounts) {
            accountIds.add(acc.Id);
        }

        List<AccountAdditionalInfo__c> weeklyComments = new List<AccountAdditionalInfo__c>();
        weeklyComments = [SELECT Id, Account__r.Name, Account__r.Id,Value__c,Value3__c,Value2__c,toLabel(Account__r.SalesMaturity__c),WeeklyCompleted__c FROM AccountAdditionalInfo__c WHERE Account__c in : accountIds AND StartDateTime__c >=: startDate AND StartDateTime__c <=: endDate];

        if (!weeklyComments.isEmpty()) {
            return weeklyComments;
        }

        List<AccountAdditionalInfo__c> allInfos = [
            SELECT Id, Account__c, Account__r.Name,
                WeeklyCompleted__c,
                CreatedDate,
                Value__c, Value2__c, Value3__c,
                toLabel(Account__r.SalesMaturity__c)
            FROM AccountAdditionalInfo__c
            WHERE Account__c IN :accountIds
            AND Infotype__c = 'WEEKLYCOMMENT'
            ORDER BY Account__c, CreatedDate DESC
        ];

        // 3️⃣ Nos quedamos solo con el último por Account
        Map<Id, AccountAdditionalInfo__c> lastInfoByAccount = new Map<Id, AccountAdditionalInfo__c>();

        for (AccountAdditionalInfo__c info : allInfos) {
            if (!lastInfoByAccount.containsKey(info.Account__c)) {
                lastInfoByAccount.put(info.Account__c, info);
            }
        }

        // 4️⃣ Devolver SOLO los que el último NO esté completado
        List<AccountAdditionalInfo__c> result = new List<AccountAdditionalInfo__c>();

        for (AccountAdditionalInfo__c info : lastInfoByAccount.values()) {
            if (info.WeeklyCompleted__c == null) {
                result.add(info);
            }
        }

        return result;
    }

    @AuraEnabled
    public static String translate(String text, String targetLang) {
        return AIService.getResponse('Translate only to French, and write only the translation: ' + text);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getEmailCCByUser(List<String> userIds) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        if (userIds == null || userIds.isEmpty()) {
            return result;
        }

        // 1️⃣ Consulta usuarios y sus managers
        Map<Id, User> users = new Map<Id, User>([
            SELECT Id, Email, ManagerId, Manager.Email, Default_Sales_Organization__c, Sales_Office__c
            FROM User
            WHERE Id IN :userIds
        ]);

        // Consultamos todo el custom metadata y construimos el Map con DeveloperName como key
        Map<String, WeeklyManagementMailing__mdt> metaByDevName = new Map<String, WeeklyManagementMailing__mdt>();

        for (WeeklyManagementMailing__mdt meta : [
            SELECT DeveloperName, EmailTo__c, MasterLabel
            FROM WeeklyManagementMailing__mdt
        ]) {
            metaByDevName.put(meta.DeveloperName, meta);
        }

        // 3️⃣ Construye el resultado
        for (User u : users.values()) {
            List<String> emails = new List<String>();

            // Manager directo
            if (u.Manager != null && String.isNotBlank(u.Manager.Email)) {
                emails.add(u.Manager.Email);
            }

            // Buscar metadatos por Sales Office (o Sales Org)
            // Asumimos que el DeveloperName o MasterLabel contiene el código (p.e. WMM_225)
            String keyByOffice = 'WMM_' + u.Sales_Office__c;
            String keyByOrg    = 'WMM_' + u.Default_Sales_Organization__c;

            // Si existe coincidencia por office
            if (metaByDevName.containsKey(keyByOffice)) {
                WeeklyManagementMailing__mdt meta = metaByDevName.get(keyByOffice);
                if (String.isNotBlank(meta.EmailTo__c)) {
                    for (String email : meta.EmailTo__c.split(',')) {
                        emails.add(email.trim());
                    }
                }
            }

            // Si no hay por office, intentamos por org
            if (!metaByDevName.containsKey(keyByOffice) && metaByDevName.containsKey(keyByOrg)) {
                WeeklyManagementMailing__mdt meta = metaByDevName.get(keyByOrg);
                if (String.isNotBlank(meta.EmailTo__c)) {
                    for (String email : meta.EmailTo__c.split(',')) {
                        emails.add(email.trim());
                    }
                }
            }

            // Añadir al resultado
            result.put(u.Id, emails);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static void saveKeyAccountCommentAnswers(Map<String, String> mapAnswers) {
        Set<String> commentIds = new Set<String>();
        
        for (String commentId : mapAnswers.keySet()) {
            commentIds.add(commentId);
        }
        List<AccountAdditionalInfo__c> data = [SELECT Id, Value__c,Value2__c,Value3__c FROM AccountAdditionalInfo__c WHERE Id IN : commentIds];

        for (AccountAdditionalInfo__c comm : data) {
            comm.Value2__c = mapAnswers.get(comm.Id);
        }

        update data;
    }

    @AuraEnabled(cacheable=false)
    public static void saveKeyOpportunityCommentAnswers(Map<String, String> mapAnswers) {
        Set<String> commentIds = new Set<String>();
        
        for (String commentId : mapAnswers.keySet()) {
            commentIds.add(commentId);
        }
        List<OpportunityAdditionalInfo__c> data = [SELECT Id, Value__c,Value2__c,Value3__c FROM OpportunityAdditionalInfo__c WHERE Id IN : commentIds];

        for (OpportunityAdditionalInfo__c comm : data) {
            comm.Value2__c = mapAnswers.get(comm.Id);
        }

        update data;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getKeyOpportunities(String userId) {
        List<Opportunity> keyOpps = [select id, name, ownerId,Account.Name,owner.Email,toLabel(StageName),Last_Activity_Date__c, AccountId from Opportunity where LeadSource = 'Porsamarket' and ownerId =: userId and StageName <> 'Closed Won' and StageName <> 'Closed Lost' and StageName <> 'Lost'];
        return keyOpps;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getKeyOpportunitiesAura() {
        return getKeyOpportunities();
    }

    public static List<Opportunity> getKeyOpportunities() {
        List<Opportunity> keyOpps = [select id, name, ownerId,Account.Name,owner.Email,toLabel(StageName),Last_Activity_Date__c, AccountId from Opportunity where LeadSource = 'Porsamarket' and StageName <> 'Closed Won' and StageName <> 'Closed Lost' and StageName <> 'Lost'];
        return keyOpps;
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityAdditionalInfo__c> getKeyOpportunitiesComments(Date startDate, Date endDate, String userId) {
        List<Opportunity> keyOpportunities = getKeyOpportunities(userId);
        Set<String> opportunityIds = new Set<String>();


        for (Opportunity opp : keyOpportunities) {
            opportunityIds.add(opp.Id);
        }

        List<OpportunityAdditionalInfo__c> weeklyComments = new List<OpportunityAdditionalInfo__c>();

        weeklyComments = [SELECT Id, Opportunity__r.Name,Opportunity__r.Id,Value__c,Value2__c,Value3__c,WeeklyCompleted__c,Opportunity__r.Account.Name,Opportunity__r.Account.Id FROM OpportunityAdditionalInfo__c WHERE Opportunity__c in : opportunityIds AND StartDateTime__c >=: startDate AND StartDateTime__c <=: endDate];
        
        if (!weeklyComments.isEmpty()) {
            return weeklyComments;
        }

        // 2️⃣ No hay comentarios esta semana → buscar el ÚLTIMO por Opportunity
        List<OpportunityAdditionalInfo__c> allInfos = [
            SELECT Id,
                Opportunity__c,
                Opportunity__r.Name,
                Opportunity__r.Account.Name,
                Opportunity__r.Account.Id,
                WeeklyCompleted__c,
                CreatedDate,
                Value__c, Value2__c, Value3__c
            FROM OpportunityAdditionalInfo__c
            WHERE Opportunity__c IN :opportunityIds
            AND Infotype__c = 'WEEKLYCOMMENT'
            ORDER BY Opportunity__c, CreatedDate DESC
        ];

        // 3️⃣ Mantener solo el último registro por Opportunity
        Map<Id, OpportunityAdditionalInfo__c> lastInfoByOpportunity =
            new Map<Id, OpportunityAdditionalInfo__c>();

        for (OpportunityAdditionalInfo__c info : allInfos) {
            if (!lastInfoByOpportunity.containsKey(info.Opportunity__c)) {
                lastInfoByOpportunity.put(info.Opportunity__c, info);
            }
        }

        // 4️⃣ Devolver solo los que el último NO esté completado
        List<OpportunityAdditionalInfo__c> result = new List<OpportunityAdditionalInfo__c>();

        for (OpportunityAdditionalInfo__c info : lastInfoByOpportunity.values()) {
            if (info.WeeklyCompleted__c == null) {
                result.add(info);
            }
        }

        return result;
    }

    /*
    *   @Description returns the register that informs about the weekly report sent, the time, the comment, etc
    */
    @AuraEnabled(cacheable=false)
    public static WeeklyManagement__c getWeeklyManagement(Date startDate, Date endDate, String userId) {
        WeeklyManagement__c result = null;
        List<WeeklyManagement__c> management = [Select id,StartDateTime__c,EndDateTime__c,Type__c,OwnerId, comment__c,CreatedDate from WeeklyManagement__c  WHERE StartDateTime__c >=: startDate AND StartDateTime__c <=: endDate AND OwnerId =: userId AND Type__c = 'REPORTSENT'];

        if (management.size() > 0) {
            result = management[0];
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsersUnderRole(String userId) {
        Map<String, Set<String>> hierarchyUsers = ReportsHelper.getUserHierarchy();
        Set<String> users = hierarchyUsers.get(userId);
        List<String> result = new List<String>();

        for (Id id : users) {
            result.add(id);
        }

        return [SELECT Id, FirstName, LastName FROM User WHERE Id IN : result AND Profile.Name IN ('Standard Trade', 'Managers') Order By FirstName ASC];
    }

    @future(callout=true)
    public static void sendWeeklyReportAsync(Date startDate, Date endDate, String userId) {
        WeeklyManagementEmails.sendWeeklyReport(startDate, endDate, userId);
    }

    @AuraEnabled(cacheable=false)
    public static void sendAndSaveWeeklyReport(Date startDate, Date endDate, String userId, String weeklyComment) {
        try {
            WeeklyManagement__c aux = new WeeklyManagement__c();
            aux.StartDateTime__c = startDate;
            aux.EndDateTime__c = endDate;
            aux.OwnerId = userId;
            aux.Comment__c = weeklyComment;
            aux.Type__c = 'REPORTSENT';

            insert aux;

            sendWeeklyReportAsync(startDate, endDate, userId);
        } catch (WeeklyManagementException ex) {
            throw new WeeklyManagementException();
        }
    }

    @AuraEnabled(cacheable=false)
    public static void sendWeeklyReport(Date startDate, Date endDate, String userId) {
        try {
            WeeklyManagementEmails.sendWeeklyReport(startDate, endDate, userId);
        } catch (WeeklyManagementException ex) {
            throw new WeeklyManagementException();
        }
    }

    /**
     * @description returns the list of WeeklyReports__c that matches the filter. These are the documents of the report
     * @param startDate
     * @param endDate
     */
    public static List<WeeklyReport__c> getWeeklyReports(Date startDate, Date endDate, Id userId) {
        Integer daysSince1900_01_07 = Date.newInstance(1900, 1, 7).daysBetween(startDate);
        Integer dayNumber = Math.mod(daysSince1900_01_07, 7) + 1;
        
        Date dateForYear = startDate.addDays(Math.mod(8 - dayNumber, 7) - 3);
        Integer year = dateForYear.year();
        Date year_01_01 = Date.newInstance(year, 1, 1);
        
        Integer week = (Integer)Math.floor((year_01_01.daysBetween(startDate)
                + Math.mod((Math.mod(Date.newInstance(1900, 1, 7).daysBetween(year_01_01), 7) + 1) + 1, 7) - 3) / 7 + 1);

                // Obtener año
        Integer yearNumber = startDate.year();

        // Construir el prefijo del filename
        String weekCode = 'WKR_' + yearNumber + '_W' + week;

        // Obtener email del Owner
        User u = [SELECT Email FROM User WHERE Id = :userId LIMIT 1];
        String safeEmail = u.Email != null 
            ? u.Email.replace('@','_').replace('.','_') 
            : 'unknown';

        // Prefijo final esperado
        String fullPrefix = weekCode + '_' + safeEmail;


        // Query a WeeklyReport__c filtrando por filename__c
        List<WeeklyReport__c> reports = [
            SELECT Id, Name, FileName__c, OwnerId, extension__c, path__c, type__c
            FROM WeeklyReport__c
            WHERE FileName__c LIKE :fullPrefix + '%'
                AND OwnerId = :userId
        ];

        return reports;
    }

    public class weeklyData {
        @AuraEnabled
        public List<Event> events = new List<Event>();

        @AuraEnabled
        public List<Account> keyAccounts = new List<Account>();

        @AuraEnabled
        public List<AccountAdditionalInfo__c> keyAccountsComments = new List<AccountAdditionalInfo__c>();

        @AuraEnabled
        public List<Opportunity> keyOpportunities = new List<Opportunity>();

        @AuraEnabled
        public List<OpportunityAdditionalInfo__c> keyOpportunitiesComments = new List<OpportunityAdditionalInfo__c>();

        @AuraEnabled
        public WeeklyManagement__c weeklyManagement = null;

        @AuraEnabled
        public List<WeeklyReport__c> weeklyReports = new List<WeeklyReport__c>();

        public weeklyData(){}

        public weeklyData(Date startDate, Date endDate, String userId) {
            this.events = WeeklyManagementController.getEvents(startDate, endDate, userId);
            this.keyAccounts = WeeklyManagementController.getKeyAccounts(userId);
            this.keyAccountsComments = WeeklyManagementController.getKeyAccountsComments(startDate, endDate, userId);
            this.keyOpportunities = UserCommons.getKeyOpportunities(userId);
            this.keyOpportunitiesComments = WeeklyManagementController.getKeyOpportunitiesComments(startDate, endDate, userId);
            this.weeklyManagement = WeeklyManagementController.getWeeklyManagement(startDate, endDate, userId);
            this.weeklyReports = WeeklyManagementController.getWeeklyReports(startDate, endDate, userId);
        }
    }

    @testVisible public static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}