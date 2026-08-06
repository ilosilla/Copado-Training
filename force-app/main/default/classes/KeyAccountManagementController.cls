/**
* @author 	Ivan Losilla
* @date 	November 2025
* @group 	Key Accounts
* @description Controller of the Component KeyAccountManagement LWC
* @test KeyAccountManagementControllerTest
*/
public class KeyAccountManagementController {
    
    public static List<AccountAdditionalInfo__c> getComments(String accountId) {
        List<AccountAdditionalInfo__c> result = [
            SELECT Id, Account__r.Name, Account__r.Id, Account__r.Last_Activity_Date__c, Value3__c,Value4__c, SentAnswer__c,Account__r.Owner.Name,Account__r.Owner.isActive,Account__r.Owner.Email,Account__r.OwnerId, Account__r.Owner.Default_Sales_Organization__c, Account__r.Owner.Manager.Name, Value__c, Value2__c, toLabel(Account__r.SalesMaturity__c), WeeklyCompleted__c, CreatedDate
            FROM AccountAdditionalInfo__c
            WHERE Account__c =: accountId
            AND Infotype__c = 'WEEKLYCOMMENT'
            AND WeeklyCompleted__c != NULL
            ORDER BY WeeklyCompleted__c DESC
        ];

        return result;
    }

    public static List<OpportunityAdditionalInfo__c> getOpportunityComments(String accountId) {
        List<OpportunityAdditionalInfo__c> result = [
            SELECT Id, Opportunity__r.Name, Opportunity__r.Id, Opportunity__r.Last_Activity_Date__c, Value3__c,Value4__c, SentAnswer__c,Opportunity__r.Owner.Name,Opportunity__r.Owner.isActive,Opportunity__r.Owner.Email,Opportunity__r.OwnerId, Opportunity__r.Owner.Default_Sales_Organization__c, Opportunity__r.Owner.Manager.Name, Value__c, Value2__c, WeeklyCompleted__c, CreatedDate
            FROM OpportunityAdditionalInfo__c
            WHERE Opportunity__r.AccountId =: accountId
            AND Infotype__c = 'WEEKLYCOMMENT'
            AND WeeklyCompleted__c != NULL
            ORDER BY WeeklyCompleted__c DESC
        ];

        return result;
    }

    public static List<String> getEmailCCByUser(String userId) {
        List<String> result = new List<String>();
        Map<String, List<String>> aux = getEmailCCByUsers(new List<String>{userId});
        if (aux.size() > 0) {
            result = aux.get(userId);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static String addCCEmailToComment(String email, String commentId) {
        AccountAdditionalInfo__c comment = [SELECT Id, Value3__c FROM AccountAdditionalInfo__c WHERE Id =: commentId];

        if (String.isBlank(comment.Value3__c)) {
            comment.Value3__c = email;
        }

        if (comment.Value3__c.contains(email) == false) {
            comment.Value3__c += ';' + email;
        }
        update comment;

        return comment.Value3__c;
    }

    @AuraEnabled(cacheable=false)
    public static String addCCUserToComment(String userId, String commentId) {
        User usr = [SELECT Id,Email FROM User WHERE Id =: userId];

        return addCCEmailToComment(usr.Email, commentId);
    }

    @AuraEnabled(cacheable=false)
    public static String removeCCEmailToComment(String email, String commentId) {
        AccountAdditionalInfo__c comment = [SELECT Id, Value3__c FROM AccountAdditionalInfo__c WHERE Id =: commentId];

        List<String> emails = new List<String>();

        for (String mail : comment.Value3__c.split(';')) {
            if (mail != email) {
                emails.add(mail);
            }
        }
        comment.Value3__c = String.join(emails,';');
        update comment;

        return comment.Value3__c;
    }

    @AuraEnabled(cacheable=false)
    public static String removeToEmailToComment(String email, String commentId) {
        AccountAdditionalInfo__c comment = [SELECT Id, Value4__c FROM AccountAdditionalInfo__c WHERE Id =: commentId];

        comment.Value4__c = null;
        update comment;

        return comment.Value4__c;
    }

    public static Map<String, List<String>> getEmailCCByUsers(List<String> userIds) {
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

    public static List<Account> getKeyAccounts() {
        List<Follow__c> follows = [select id, Account__r.ownerId, Account__r.name, Owner.Alias from Follow__c where RecordType.name = 'Account' and Owner.Alias IN ('ssega','MPrio', 'JB', 'PSimar')];
        Set<String> accountIds = new Set<String>();


        for (Follow__c follow : follows) {
            accountIds.add(follow.Account__c);
        }

        return [SELECT id,Last_Activity_Date__c,toLabel(Account_Classification__c),Account_Status__c,Name, Phone, Business_Email__c FROM Account WHERE Id in : accountIds];
    }

    @AuraEnabled(cacheable=false)
    public static List<AccountAdditionalInfo__c> getLastKeyAccountsComments() {
        List<Account> keyAccounts = getKeyAccounts();
        Set<String> accountIds = new Set<String>();

        for (Account acc : keyAccounts) {
            accountIds.add(acc.Id);
        }

        List<AccountAdditionalInfo__c> infos = [
            SELECT Id, Account__r.Name, Account__r.Id, Account__r.Last_Activity_Date__c, SentAnswer__c,Value3__c,Value4__c,Account__r.Owner.Name,Account__r.Owner.isActive,Account__r.Owner.Email,Account__r.OwnerId, Account__r.Owner.Default_Sales_Organization__c, Account__r.Owner.Manager.Name, Value__c, Value2__c, toLabel(Account__r.SalesMaturity__c), WeeklyCompleted__c, CreatedDate
            FROM AccountAdditionalInfo__c
            WHERE Account__c IN :accountIds
            AND Infotype__c = 'WEEKLYCOMMENT'
            AND WeeklyCompleted__c != NULL
            ORDER BY Account__c, WeeklyCompleted__c DESC
        ];

        // Map para mantener solo el más reciente por Account
        Map<Id, AccountAdditionalInfo__c> mostRecentByAccount = new Map<Id, AccountAdditionalInfo__c>();

        for (AccountAdditionalInfo__c info : infos) {
            if (!mostRecentByAccount.containsKey(info.Account__c)) {
                mostRecentByAccount.put(info.Account__c, info);
            }
        }

        return mostRecentByAccount.values();
    }

    @AuraEnabled(cacheable=false)
    public static void removeAsKey(String accountId) {
        Savepoint sp = Database.setSavepoint();

        try {
            Set<String> userIds = new Set<String>();
            for (User usr : [SELECT Id, Alias, Name FROM User WHERE Alias IN ('ssega','MPrio', 'JB', 'PSimar')]) {
                userIds.add(usr.Id);
            }
            
            List<Follow__c> follows = [SELECT Id FROM Follow__c WHERE Account__c =: accountId and OwnerId IN : userIds];
            List<EntitySubscription> subscriptions = [SELECT Id FROM EntitySubscription WHERE ParentId =: accountId and SubscriberId IN : userIds];

            delete follows;
            delete subscriptions;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }        
    }

    public static void removeAsKey(List<String> accountIds) {
        Savepoint sp = Database.setSavepoint();

        try {
            Set<String> userIds = new Set<String>();
            for (User usr : [SELECT Id, Alias, Name FROM User WHERE Alias IN ('ssega','MPrio', 'JB', 'PSimar')]) {
                userIds.add(usr.Id);
            }
            
            List<Follow__c> follows = [SELECT Id FROM Follow__c WHERE Account__c IN :accountIds and OwnerId IN : userIds];
            List<EntitySubscription> subscriptions = [SELECT Id FROM EntitySubscription WHERE ParentId IN :accountIds and SubscriberId IN : userIds];

            delete follows;
            delete subscriptions;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }        
    }

    @AuraEnabled(cacheable=false)
    public static keyAccountData getData(String accountId) {
        return new KeyAccountData(accountId);
    }

    public class keyAccountData {
        @AuraEnabled
        public Account accountData = new Account();

        @AuraEnabled
        public List<AccountAdditionalInfo__c> comments = new List<AccountAdditionalInfo__c>();

        @AuraEnabled
        public List<Opportunity> opportunities = new List<Opportunity>();

        @AuraEnabled
        public List<OpportunityAdditionalInfo__c> opportunityComments = new List<OpportunityAdditionalInfo__c>();

        @AuraEnabled
        public List<AccountTeamMember> teamMembers = new List<AccountTeamMember>();

        @AuraEnabled
        public List<Follow__c> follows = new List<Follow__c>();

        @AuraEnabled
        public List<String> emailCC = new List<String>();

        @AuraEnabled
        public List<Task> tasks = new List<Task>();

        @AuraEnabled
        public List<Event> events = new List<Event>();

        @AuraEnabled
        public List<Contact> contacts = new List<Contact>();

        public keyAccountData(){}

        public keyAccountData(String accountId) {
            Set<Id> contactIds = new Set<Id>();

            for (Contact c : [SELECT Id FROM Contact WHERE AccountId = :accountId]) {
                contactIds.add(c.Id);
            }

            this.accountData = [SELECT Id, Name, Last_Activity_Date__c,OwnerId,Owner.Name,SalesMaturity__c,Activity_Level__c FROM Account WHERE Id =: accountId];
            this.comments = getComments(accountId);
            this.opportunities = [SELECT Id, Name, Last_Activity_Date__c, Activity_Level__c, IsClosed,StageName, Owner.Name, LeadSource FROM Opportunity WHERE AccountId =: accountId];
            this.opportunityComments = getOpportunityComments(accountId);
            this.teamMembers = [SELECT Id, UserId, AccountId, TeamMemberRole, User.Name, User.Email FROM AccountTeamMember WHERE AccountId =: accountId];
            this.follows = [SELECT Id, OwnerId, Owner.Name, Owner.Email FROM Follow__c WHERE Account__c =: accountId AND RecordType.Name = 'Account'];
            this.emailCC = getEmailCCByUser(this.accountData.OwnerId);
            this.tasks = [SELECT Id, Subject, Status, ActivityDate, Owner.Name,WhoId, WhatId FROM Task WHERE (WhatId = :accountId OR WhoId IN :contactIds) ORDER BY ActivityDate DESC LIMIT 50];
            this.events = [SELECT Id, Subject, StartDateTime, EndDateTime, Owner.Name, WhoId, WhatId FROM Event WHERE isChild = false AND (WhatId = :accountId OR WhoId IN :contactIds) ORDER BY StartDateTime DESC LIMIT 50];
            this.contacts = [SELECT Id, Name, Email, Phone, Title, Owner.Name, LastActivityDate FROM Contact WHERE AccountId = :accountId ORDER BY LastActivityDate DESC NULLS LAST];
        }
    }
}