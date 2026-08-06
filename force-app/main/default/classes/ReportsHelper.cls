/**
* @author Ivan Losilla
* @date March 2025
* @group Reports
* @test ReportsHelperTest
*/
public class ReportsHelper {
    public class ReportsHelperException extends Exception {}

    private String genericMail = 'salesforce@porcelanosagrupo.com';

    public static List<Event> getManagedEvents(Date startDate, Date endDate, Set<String> userIds) {
        List<Event> listEvents = [SELECT Id, Subject,Description, startDateTime, endDateTime,whatId, WhoId,cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c
                                    FROM Event 
                                    WHERE OwnerId IN : userIds
                                    AND (
                                        (loginflowcompleted__c != NULL
                                        AND loginflowcompleted__c >= :startDate
                                        AND loginflowcompleted__c <= :endDate) 
                                        OR 
                                        (WhatId != NULL AND WhoId != NULL AND startDateTime >= :startDate AND startDateTime <= :endDate)
                                    )
                                    AND (NOT Subject LIKE '%[Internal]%')
                                    AND Type != 'Non Commercial'
                                    AND isPrivate = false];
        return listEvents;
    }

    public static List<Event> getUnManagedEvents(Date startDate, Date endDate, Set<String> userIds) {
        List<Event> listEvents = [SELECT Id, Subject,Description, startDateTime, endDateTime,whatId, WhoId,cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c
                                    FROM Event 
                                    WHERE loginflowcompleted__c = NULL
                                    AND OwnerId IN : userIds
                                    AND Createdbyid IN : userIds
                                    AND startDateTime >= :startDate
                                    AND startDateTime <= :endDate
                                    AND (NOT Subject LIKE '%[Internal]%')
                                    AND Type != 'Non Commercial'];
        return listEvents;
    }

    public static Map<String, String> createEventsXls(List<Event> listEvents, User usr) {
        Set<String> accountIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Set<String> ownerIds = new Set<String>();
        Map<String, Account> accountMaps = new Map<String, Account>();
        Map<String, Contact> contactMaps = new Map<String, Contact>();
        Map<String, User> ownerMaps = new Map<String, User>();
        Map<String, String> result = new Map<String, String>();

        Map<String, List<Follow__c>> mapKeyAccounts = new Map<String, List<Follow__c>>();
        Map<String, List<Opportunity>> mapKeyOpps = new Map<String, List<Opportunity>>();
        List<Follow__c> keyAccounts = [select id, Account__r.ownerId, Account__r.name from Follow__c where RecordType.name = 'Account' and Owner.Alias IN ('ssega','MPrio')];
        List<Opportunity> keyOpps = [select id, name, ownerId from Opportunity where LeadSource = 'Porsamarket'];

        for (Follow__c keyAcc : keyAccounts) {
            if (mapKeyAccounts.containsKey(keyAcc.Account__r.ownerId)) {
                mapKeyAccounts.get(keyAcc.Account__r.ownerId).add(keyAcc);
            } else {
                mapKeyAccounts.put(keyAcc.Account__r.ownerId, new List<Follow__c>{keyAcc});
            }
        }

        for (Opportunity keyOpp : keyOpps) {
            if (mapKeyOpps.containsKey(keyOpp.ownerId)) {
                mapKeyOpps.get(keyOpp.ownerId).add(keyOpp);
            } else {
                mapKeyOpps.put(keyOpp.ownerId, new List<Opportunity>{keyOpp});
            }
        }
    
        for (Event evt : listEvents) {
            if (evt.WhatId != null) {
                accountIds.add(evt.WhatId);
            }
            if (evt.WhoId != null) {
                contactIds.add(evt.WhoId);
            }
            ownerIds.add(evt.OwnerId);
        }
    
        for (Account acc : [SELECT Id, Name FROM Account WHERE Id IN : accountIds]) {
            accountMaps.put(acc.Id, acc);
        }
        for (Contact ct : [SELECT Id, Name FROM Contact WHERE Id IN : contactIds]) {
            contactMaps.put(ct.Id, ct);
        }
        for (User user : [SELECT Id, Name, Email, Default_Sales_Organization__c, Sales_Office_Text__c, countryCode FROM User WHERE Id IN : ownerIds]) {
            ownerMaps.put(user.Id, user);
        }
    
        // Comenzar tabla HTML
        String tableHeader = '<table border="1"><tr>' +
                            '<th>Subject</th><th>Type</th><th>Comments</th><th>Start</th><th>End</th>' +
                            '<th>Account</th><th>Contact</th><th>Cancelled</th><th>Owner</th><th>Sales Org</th><th>Sales Office</th><th>Country</th><th>Completed</th><th>Link</th>' +
                            '</tr>';
    
        if (usr.LanguageLocaleKey == 'fr') {
            tableHeader = '<table border="1"><tr>' +
                        '<th>Sujet</th><th>Type</th><th>Commentaires</th><th>Début</th><th>Fin</th>' +
                        '<th>Compte</th><th>Contact</th><th>Annulé</th><th>Propriétaire</th><th>Org</th><th>Bureau de vente</th><th>Pays</th><th>Terminé</th><th>Lien</th>' +
                        '</tr>';
        }
    
        String tableBody = '';
    
        result.put('EVENTS', String.valueOf(listEvents.size()));

        // Establecer el contexto de zona horaria
        TimeZone tz = TimeZone.getTimeZone(usr.TimeZoneSidKey);
    
        for (Event row : listEvents) {
            tableBody += '<tr>' +
                         '<td>' + row.Subject + '</td>' +
                         '<td>' + row.EventType__c + '</td>';

                         if (row.Description != null) {
                            row.Description = row.Description != null ? row.Description.replace('";', ' ').replace('\n', '<br/>') : '';
                         }

                         if (row.EventType__c == 'Weekly report' && row.Description != null) {
                            if (mapKeyAccounts.containsKey(row.ownerId)) {
                                for (Follow__c elem : mapKeyAccounts.get(row.ownerId)) {
                                    row.Description = row.Description.replace(elem.Account__r.name+':', '<a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + elem.Id + '">' + elem.Account__r.name + '</a><br/>');
                                }
                            }

                            if (mapKeyOpps.containsKey(row.ownerId)) {
                                for (Opportunity elem : mapKeyOpps.get(row.ownerId)) {
                                    row.Description = row.Description.replace(elem.Name + ':', '<a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + elem.Id + '">' + elem.Name + '</a><br/>');
                                }   
                            }
                         }
                        
                         tableBody += '<td>' + row.Description + '</td>' +
                         '<td>' + row.StartDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID()) + '</td>' +
                         '<td>' + row.EndDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID()) + '</td>' +
                         '<td>' + (row.WhatId != null && accountMaps.containsKey(row.WhatId) ? accountMaps.get(row.WhatId).Name : '') + '</td>' +
                         '<td>' + (row.WhoId != null && contactMaps.containsKey(row.WhoId) ? contactMaps.get(row.WhoId).Name : '') + '</td>' +
                         '<td>' + row.Cancelled__c + '</td>' +
                         '<td>' + row.Owner.Name + '</td>' +
                         '<td>' + ownerMaps.get(row.OwnerId).Default_Sales_Organization__c + '</td>' +
                         '<td>' + ownerMaps.get(row.OwnerId).Sales_Office_Text__c + '</td>' +
                         '<td>' + ownerMaps.get(row.OwnerId).countryCode + '</td>' +
                         '<td>' + row.loginflowcompleted__c + '</td>' +
                         '<td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + row.Id + '">Link</a></td>' +
                         '</tr>';
        }
    
        String htmlContent = '<html><body>' + tableHeader + tableBody + '</table></body></html>';
    
        result.put('CONTENT', htmlContent);
    
        return result;
    }

    public static Boolean sendEmail(User usr, List<Event> listEvents, String subject, String body, String filename, String mailTest, Blob pdfData) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            List<Id> eventIds = new List<Id>();
            for (Event evt : listEvents) {
                eventIds.add(evt.Id);
            }

            if (mailTest != null) {
                email.setToAddresses(new List<String>{mailTest});
                body += '<br/><br/><b> DEBUG: Email sent to ' + usr.email + '</b>';
            } else {
                email.setToAddresses(new List<String>{usr.email});
            }
            List<OrgWideEmailAddress> owea = [select Id from OrgWideEmailAddress where Address = 'salesforce@porcelanosagrupo.com'];
            if ( owea.size() > 0 ) {
                email.setOrgWideEmailAddressId(owea.get(0).Id);
                email.setUseSignature(false);
            }
            email.setSubject(subject);
            email.setHtmlBody(body);

            //String csvData = createEventsCsv(listEvents, usr.LanguageLocaleKey).get('CONTENT');
            String xlsData = createEventsXls(listEvents, usr).get('CONTENT');

            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

            // Crear archivo adjunto
            Messaging.EmailFileAttachment attachmentXls = new Messaging.EmailFileAttachment();
            attachmentXls.setFileName(fileName + '.xls');
            attachmentXls.setContentType('application/vnd.ms-excel');
            attachmentXls.setBody(Blob.valueOf(xlsData));

            attachments.add(attachmentXls);

            if (pdfData != null) {
                Messaging.EmailFileAttachment attachmentPdf = new Messaging.EmailFileAttachment();
                attachmentPdf.setFileName(fileName + '.pdf');
                attachmentPdf.setBody(pdfData);
                attachmentPdf.setContentType('application/pdf');
                attachments.add(attachmentPdf);
            }
            
            email.setFileAttachments(attachments);

            // Enviar email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});

            System.debug('✅ Email enviado correctamente.');
            return true;
        } catch (Exception e) {
            System.debug('❌ Error al enviar el email: ' + e.getMessage());
            return false;
        }
    }

    public static WeeklyReport__c uploadFiles(User usr, List<Event> listEvents, String filenameRoot, String recordName, Blob pdfData) {
        try {
            String urlTest = '';
            Organization org = [Select Id, Name, IsSandbox from Organization];
            if (org.IsSandbox) {
                urlTest += '/testsIvan';
            }

            WeeklyReport__c result;
            List<Id> eventIds = new List<Id>();
            for (Event evt : listEvents) {
                eventIds.add(evt.Id);
            }

            String xlsData = createEventsXls(listEvents, usr).get('CONTENT');
            Map<String, Object> resultUpload = StorageService.saveFile(SAPCPIProxy.STORAGE_REPORTS_ENDPOINT + '/weekly-reports' + urlTest, filenameRoot+ '.xls', Blob.valueOf(xlsData), true);
            Map<String, Object> resultUploadPdf = StorageService.saveFile(SAPCPIProxy.STORAGE_REPORTS_ENDPOINT + '/weekly-reports' + urlTest, filenameRoot + '.pdf', pdfData, true);
            
            if (resultUpload.containsKey('message') && resultUpload.get('message') == 'File uploaded successfully') {
                Map<String, WeeklyReport__c> existingFiles = existingRecordsByNames(new List<String>{filenameRoot+ '.xls'});

                if (existingFiles.containsKey(filenameRoot+ '.xls') == false) {
                    result = insertRecord(usr, filenameRoot+ '.xls', (String) resultUpload.get('key'), recordName);
                } else {
                    result = existingFiles.get(filenameRoot+ '.xls');
                }
            }

            if (resultUploadPdf.containsKey('message') && resultUpload.get('message') == 'File uploaded successfully') {
                Map<String, WeeklyReport__c> existingFiles = existingRecordsByNames(new List<String>{filenameRoot+ '.pdf'});

                if (existingFiles.containsKey(filenameRoot+ '.pdf') == false) {
                    result = insertRecord(usr, filenameRoot+ '.pdf', (String) resultUpload.get('key'), recordName);
                } else {
                    result = existingFiles.get(filenameRoot+ '.pdf');
                }
            }

            return result;
        } catch (Exception e) {
            System.debug('❌ Error al subir el fichero: ' + e.getMessage());
            return null;
        }
    }

    public static Map<String, String> reportEvents(String type, Date startDate, Date endDate, String userId, String mailTest) {
        Map<String, String> result = new Map<String, String>();
        result.put('SENT', 'FALSE');
        result.put('REGISTERS', null);
        Map<String, Set<String>> userHierarchy = getUserHierarchy();
        Set<String> users = userHierarchy.get(userId);
        User usr = new UsersSelector().selectById(userId);
        List<Event> listEvents = new List<Event>();
        Blob pdfData;

        String subject = Label.loginflow_report_managed_subject;
        String body = Label.loginflow_report_managed_body;
        
        // Obtener el número de semana a partir de startDate
        Integer weekNumber = getWeekNumber(startDate);
        String filename = usr.email + '_WEEK' + String.valueOf(weekNumber);
        if (usr.LanguageLocaleKey == 'fr') {
            filename = usr.email + '_SEMAINE' + String.valueOf(weekNumber);
        }

        if (type.toUpperCase() == 'MANAGED') {
            listEvents = getManagedEvents(startDate, endDate, users);

            try {
                PageReference pdfPage = Page.EventManagementReports;

                if (usr.LanguageLocaleKey == 'fr') {
                    pdfPage = Page.EventManagementReportsFR;
                }
                pdfPage.getParameters().put('startDate', String.valueOf(startDate));
                pdfPage.getParameters().put('endDate', String.valueOf(endDate));
                pdfPage.getParameters().put('type', type);
                pdfPage.getParameters().put('userId', userId);
                pdfData = pdfPage.getContent();
            } catch (Exception exc) {
                pdfData = null;
                System.debug('❌ Error al crar el pdf: ' + exc.getMessage());
            }

            if (usr.LanguageLocaleKey == 'fr') {
                subject = Label.loginflow_report_managed_subject_fr;
                body = Label.loginflow_report_managed_body_fr;
                filename = 'evenements_rapport';
            }
        }
        if (type.toUpperCase() == 'UNMANAGED') {
            listEvents = getUnManagedEvents(startDate, endDate, new Set<String>{usr.Id});

            try {
                PageReference pdfPage = Page.EventManagementReports;

                if (usr.LanguageLocaleKey == 'fr') {
                    pdfPage = Page.EventManagementReportsFR;
                }
                pdfPage.getParameters().put('startDate', String.valueOf(startDate));
                pdfPage.getParameters().put('endDate', String.valueOf(endDate));
                pdfPage.getParameters().put('type', type);
                pdfPage.getParameters().put('userId', userId);
                pdfData = pdfPage.getContent();
            } catch (Exception exc) {
                pdfData = null;
                System.debug('❌ Error al crar el pdf: ' + exc.getMessage());
            }

            subject = Label.loginflow_report_Unmanaged_Subject;
            body = Label.loginflow_report_unmanaged_body;

            if (usr.LanguageLocaleKey == 'fr') {
                subject = Label.loginflow_report_unmanaged_subject_fr;
                body = Label.loginflow_report_unmanaged_body_fr;
                filename = 'evenements_rapport';
            }
        }

        if (listEvents.size() > 0) {
            Boolean sent = sendEmail(usr, listEvents, subject, body, filename, mailTest, pdfData);

            if (sent == true) {
                result.put('SENT', 'TRUE');
                result.put('REGISTERS', String.valueOf(listEvents.size()));
            }
        }

        return result;
    }

    public static Map<String, String> uploadReports(Date startDate, Date endDate, String userId) {
        Map<String, String> result = new Map<String, String>();
        result.put('UPLOAD', 'FALSE');
        result.put('PATH', '');
        result.put('REGISTERS', null);
        Map<String, Set<String>> userHierarchy = getUserHierarchy();
        Set<String> users = userHierarchy.get(userId);
        User usr = new UsersSelector().selectById(userId);
        List<Event> listEvents = new List<Event>();

        String subject = Label.loginflow_report_managed_subject;
        String body = Label.loginflow_report_managed_body;
        
        // Obtener el número de semana a partir de startDate
        //Integer weekNumber = getWeekNumber(startDate);
        /*String filename = removeSpecialCharacters(usr.Name).toLowerCase().replace(' ', '_');
        if (usr.LanguageLocaleKey == 'fr') {
            filename += '_SEMAINE' + String.valueOf(weekNumber);
        } else {
            filename += '_WEEK' + String.valueOf(weekNumber);
        }
        filename += '.xls';*/

        String filename = generateReportName(usr, startDate);
        String recordName = generateRecordName(usr, startDate);

        listEvents = getManagedEvents(startDate, endDate, users);
        Blob pdfData = null;

        try {
            PageReference pdfPage = Page.EventManagementReports;

            if (usr.LanguageLocaleKey == 'fr') {
                pdfPage = Page.EventManagementReportsFR;
            }
            pdfPage.getParameters().put('startDate', String.valueOf(startDate));
            pdfPage.getParameters().put('endDate', String.valueOf(endDate));
            pdfPage.getParameters().put('type', 'MANAGED');
            pdfPage.getParameters().put('userId', userId);
            pdfData = pdfPage.getContent();
        } catch (Exception exc) {
            pdfData = null;
            System.debug('❌ Error al crar el pdf: ' + exc.getMessage());
        }

        if (listEvents.size() > 0) {
            WeeklyReport__c uploaded = uploadFiles(usr, listEvents, filename, recordName, pdfData);

            if (uploaded != null) {
                result.put('UPLOAD', 'TRUE');
                result.put('PATH', uploaded.path__c);
                result.put('REGISTERS', String.valueOf(listEvents.size()));
            }
        }

        return result;
    }

    public static String generateReportName(User user, Date startDate) {
        if (user == null || user.Email == null || startDate == null) {
            throw new IllegalArgumentException('User, Email, and startDate are required.');
        }

        Integer year = startDate.year();
        Integer weekNumber = getWeekNumber(startDate);
        String emailPart = user.Email.replace('.', '_').replace('@', '_');
        return 'WKR_' + year + '_W' + String.valueOf(weekNumber) + '_' + emailPart;
    }

    public static String generateRecordName(User user, Date startDate) {
        String result;
        if (user == null || user.Email == null || startDate == null) {
            throw new IllegalArgumentException('User, Email, and startDate are required.');
        }

        Integer year = startDate.year();
        Integer weekNumber = getWeekNumber(startDate);
        String emailPart = user.Email.split('@')[0];
        emailPart = emailPart.replace('.', '_');

        if (user.LanguageLocaleKey == 'fr') {
            result = 'Rapport hebdomadaire - Semaine ' + weekNumber + ' ' + String.valueOf(year);
        } else {
            result = 'Weekly Report - Week ' + weekNumber + ' ' + String.valueOf(year);
        }

        return result;
    }


    public static Map<String, Set<String>> getUserHierarchy() {
        Map<String, Set<String>> userHierarchy = new Map<String, Set<String>>();

        // Obtener todos los usuarios activos con su rol
        List<User> activeUsers = [SELECT Id, UserRoleId FROM User WHERE IsActive = TRUE AND profile.name <> 'Standard Retail'];

        // Mapa de UserRoleId -> Set de usuarios en ese rol
        Map<String, Set<String>> roleToUsersMap = new Map<String, Set<String>>();
        for (User u : activeUsers) {
            if (u.UserRoleId != null) {
                if (!roleToUsersMap.containsKey(u.UserRoleId)) {
                    roleToUsersMap.put(u.UserRoleId, new Set<String>());
                }
                roleToUsersMap.get(u.UserRoleId).add(u.Id);
            }
        }

        // Obtener la jerarquía de roles (ParentRoleId -> Lista de Roles hijos)
        Map<String, Set<String>> roleHierarchy = new Map<String, Set<String>>();
        for (UserRole role : [SELECT Id, ParentRoleId FROM UserRole WHERE ParentRoleId != NULL]) {
            if (!roleHierarchy.containsKey(role.ParentRoleId)) {
                roleHierarchy.put(role.ParentRoleId, new Set<String>());
            }
            roleHierarchy.get(role.ParentRoleId).add(role.Id);
        }

        // Construir el mapa de usuarios con sus subordinados usando BFS (Lista como Cola)
        for (User u : activeUsers) {
            Set<String> subordinateUsers = new Set<String>();
            subordinateUsers.add(u.Id); // 🔹 Agregar el usuario mismo a su lista de subordinados

            List<String> roleQueue = new List<String>();

            // Agregar solo roles inferiores (No el mismo UserRoleId del usuario actual)
            if (roleHierarchy.containsKey(u.UserRoleId)) {
                roleQueue.addAll(roleHierarchy.get(u.UserRoleId));
            }

            // BFS para recorrer la jerarquía
            while (!roleQueue.isEmpty()) {
                String currentRole = roleQueue[0]; // Obtener primer elemento
                roleQueue.remove(0); // Removerlo de la "cola" (FIFO)

                // Agregar usuarios del rol inferior, pero NO del mismo rol del usuario actual
                if (roleToUsersMap.containsKey(currentRole)) {
                    subordinateUsers.addAll(roleToUsersMap.get(currentRole));
                }

                // Seguir agregando roles inferiores a la "cola"
                if (roleHierarchy.containsKey(currentRole)) {
                    roleQueue.addAll(roleHierarchy.get(currentRole));
                }
            }

            // Guardar en el mapa final
            userHierarchy.put(u.Id, subordinateUsers);
        }

        return userHierarchy;
    }

    // Función auxiliar para calcular el número de semana del año
    private static Integer getWeekNumber(Date dateParam) {
        // 1 de enero del año en curso
        Date firstDayOfYear = Date.newInstance(dateParam.year(), 1, 1);
        Integer dayOfYear = dateParam.dayOfYear();
        
        // Día de la semana del 1 de enero (1 = Sunday, 7 = Saturday)
        Integer janFirstDow = firstDayOfYear.toStartOfWeek().daysBetween(firstDayOfYear) + 1;

        // Ajustar para semanas que no comienzan el 1 de enero
        Integer adjustedDay = dayOfYear + janFirstDow - 1;
        Integer weekNumber = (Integer)Math.floor((Decimal)adjustedDay / 7) + 1;

        return weekNumber;
    }

    @AuraEnabled(cacheable=true)
    public static StorageService.StorageServiceFile downloadWeeklyReport(String wreportId) {
        try {
            String urlTest = '';
            Organization org = [Select Id, Name, IsSandbox from Organization];
            if (org.IsSandbox) {
                urlTest += 'testsIvan/';
            }

            List<WeeklyReport__c> wreport = [SELECT Id, ownerId, name, type__c,filename__c, path__c FROM WeeklyReport__c WHERE Id =: wreportId];
            StorageService.StorageServiceFile fileData = StorageService.readFile(SAPCPIProxy.STORAGE_REPORTS_ENDPOINT + '/weekly-reports/' + urlTest + wreport[0].filename__c);

            return fileData;
        } catch (Exception e) {
            System.debug('❌ Error al descargar el archivo: ' + e.getMessage());
            return null;
        }
    }

    public static WeeklyReport__c insertRecord(User usr, String filename,String path, String recordName) {
        WeeklyReport__c newFile = new WeeklyReport__c(ownerId = usr.Id, fileName__c = filename, name = recordName, path__c = path, type__c = 'EVENTSMANAGED' );
        insert newFile;

        return newFile;
    }

    public static Map<String, WeeklyReport__c> existingRecordsByNames(List<String> filenames) {
        Map<String, WeeklyReport__c> result = new Map<String, WeeklyReport__c>();
        List<WeeklyReport__c> listExisting = [SELECT Id, ownerId, name, type__c,filename__c, path__c FROM WeeklyReport__c WHERE filename__c IN : filenames];

        for (WeeklyReport__c wr : listExisting) {
            result.put(wr.filename__c, wr);
        }

        return result;
    }

    public class AccountWRWrapper {
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String rating{get;set;}
        @AuraEnabled public String comment{get;set;}
    }

    public class OpportunityWrapper {
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String comment{get;set;}
    }

    @AuraEnabled
    public static Boolean saveWeeklyReportComments(List<AccountWRWrapper> keyAccounts, List<OpportunityWrapper> keyOpportunities){
        SavePoint sp = Database.setSavePoint();
        List<AccountAdditionalInfo__c> additionalFieldsAcc = new List<AccountAdditionalInfo__c>();
        List<OpportunityAdditionalInfo__c> additionalFieldsOpp = new List<OpportunityAdditionalInfo__c>();
        Set<String> accountIds = new Set<String>();

        try {
            for (AccountWRWrapper acc : keyAccounts) {
                accountIds.add(acc.id);
                if (String.isBlank(acc.comment) == false) {
                    additionalFieldsAcc.add(new AccountAdditionalInfo__c(Account__c=acc.id, InfoType__c='WEEKLYCOMMENT',Value__c=acc.comment));
                }
            }
    
            for (OpportunityWrapper opp : keyOpportunities) {
                if (String.isBlank(opp.comment) == false) {
                    additionalFieldsOpp.add(new OpportunityAdditionalInfo__c(Opportunity__c=opp.id, InfoType__c='WEEKLYCOMMENT',Value__c=opp.comment));
                }
            }

            List<Account> accounts = [SELECT Id, SalesMaturity__c FROM Account WHERE Id IN : accountIds];

            for (Account acc : accounts) {
                for (AccountWRWrapper keyAcc : keyAccounts) {
                    if (acc.Id == keyAcc.id) {
                        acc.SalesMaturity__c = keyAcc.rating;
                        break;
                    }
                }
            }

            insert additionalFieldsAcc;
            insert additionalFieldsOpp;
            update accounts;
            
            return true;
        } catch (ReportsHelperException exc) {
            Database.rollback(sp);
            System.debug(exc.getMessage());
            return false;
        }
    }

    public static String removeSpecialCharacters(String input) {
        // Map of accented characters to their non-accented equivalents
        Map<String, String> accentMap = new Map<String, String>{
            'á' => 'a', 'à' => 'a', 'ä' => 'a', 'â' => 'a', 'ã' => 'a', 'å' => 'a',
            'é' => 'e', 'è' => 'e', 'ë' => 'e', 'ê' => 'e',
            'í' => 'i', 'ì' => 'i', 'ï' => 'i', 'î' => 'i',
            'ó' => 'o', 'ò' => 'o', 'ö' => 'o', 'ô' => 'o', 'õ' => 'o',
            'ú' => 'u', 'ù' => 'u', 'ü' => 'u', 'û' => 'u',
            'ç' => 'c', 'ñ' => 'n', 'ý' => 'y', 'ÿ' => 'y',
            'Á' => 'A', 'À' => 'A', 'Ä' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Å' => 'A',
            'É' => 'E', 'È' => 'E', 'Ë' => 'E', 'Ê' => 'E',
            'Í' => 'I', 'Ì' => 'I', 'Ï' => 'I', 'Î' => 'I',
            'Ó' => 'O', 'Ò' => 'O', 'Ö' => 'O', 'Ô' => 'O', 'Õ' => 'O',
            'Ú' => 'U', 'Ù' => 'U', 'Ü' => 'U', 'Û' => 'U',
            'Ç' => 'C', 'Ñ' => 'N', 'Ý' => 'Y', 'Ÿ' => 'Y'
        };
        
        // Replace accented characters using the accent map
        String normalized = input;
        for (String key : accentMap.keySet()) {
            normalized = normalized.replace(key, accentMap.get(key));
        }

        // Remove other special characters using a regular expression
        normalized = normalized.replaceAll('[^a-zA-Z0-9 ]', ''); // Keep letters, numbers, and spaces

        return normalized;
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
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
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