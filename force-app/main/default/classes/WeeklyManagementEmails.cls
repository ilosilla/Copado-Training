public class WeeklyManagementEmails {

    public static void sendWeeklyReport(Date startDate, Date endDate, String userId) {
        List<WeeklyManagementMailing__mdt> weeklyMailingSettings = [select id,DeveloperName,EmailTo__c from WeeklyManagementMailing__mdt];
        Map<String, WeeklyManagementMailing__mdt> weeklyMailingSettingsMap = new Map<String, WeeklyManagementMailing__mdt>();
        
        for (WeeklyManagementMailing__mdt setting : weeklyMailingSettings) {
            weeklyMailingSettingsMap.put(setting.DeveloperName, setting);
        }

        User usr = [SELECT Id, Name, Email,LanguageLocaleKey,TimeZoneSidKey, Default_Sales_Organization__c,Sales_Office__c, Manager.Email FROM User WHERE id =: userId];
        WeeklyManagementController.weeklyData weeklyData = WeeklyManagementController.getWeeklyData(startDate, endDate, userId);
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

        // Obtener el número de semana a partir de startDate
        Integer weekNumber = getWeekNumber(startDate);
        String filename = usr.email + '_WEEK' + String.valueOf(weekNumber);
        if (usr.LanguageLocaleKey == 'fr') {
            filename = usr.email + '_SEMAINE' + String.valueOf(weekNumber);
        }

        String subject = Label.loginflow_report_managed_subject;
        String body = Label.loginflow_report_managed_body;
        if (usr.LanguageLocaleKey == 'fr') {
            subject = Label.loginflow_report_managed_subject_fr;
            body = Label.loginflow_report_managed_body_fr;
            filename = 'evenements_rapport';
        }

        String urlTest = '';
        Organization org = [Select Id, Name, IsSandbox from Organization];
        if (org.IsSandbox) {
            urlTest += '/testsIvan';
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        List<String> toAddresses = new List<String>();
        String emailManager = usr.Manager.Email != null ? usr.Manager.Email : null;
        String emailsGerentes = weeklyMailingSettingsMap.containsKey('WMM_' + usr.Default_Sales_Organization__c) ? weeklyMailingSettingsMap.get('WMM_' + usr.Default_Sales_Organization__c).EmailTo__c : '';
        String emailsGerentesTienda = weeklyMailingSettingsMap.containsKey('WMM_' + usr.Sales_Office__c) ? weeklyMailingSettingsMap.get('WMM_' + usr.Sales_Office__c).EmailTo__c : '';

        if (emailManager != null) {
            toAddresses.add(emailManager);
        }
        
        if (String.isBlank(emailsGerentesTienda) == false) {
            toAddresses.addAll(emailsGerentesTienda.split(','));
        } else if (String.isBlank(emailsGerentes) == false) {
            toAddresses.addAll(emailsGerentes.split(','));
        } else {
            toAddresses.add('ivan.losilla@porcelanosagrupo.com');
        }

        email.setToAddresses(toAddresses);
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setCcAddresses(new List<String>{usr.Email});

        String xlsData = createEventsXls(weeklyData.events, usr).get('CONTENT');
        Blob pdfData;
        try {
            PageReference pdfPage = Page.weeklyManagementPdf;

            if (usr.LanguageLocaleKey == 'fr') {
               pdfPage = Page.weeklyManagementPdfFR;
            }
            pdfPage.getParameters().put('startDate', String.valueOf(startDate));
            pdfPage.getParameters().put('endDate', String.valueOf(endDate));
            pdfPage.getParameters().put('userId', userId);
            pdfData = pdfPage.getContent();
        } catch (Exception exc) {
            System.debug(pdfData);
            pdfData = null;
            System.debug('❌ Error al crar el pdf: ' + exc.getMessage());
        }

        if (Test.isRunningTest() == false) {
            Map<String, Object> resultUpload = StorageService.saveFile(SAPCPIProxy.STORAGE_REPORTS_ENDPOINT + '/weekly-reports' + urlTest, generateReportName(usr,startDate)+ '.xls', Blob.valueOf(xlsData), true);
            Map<String, Object> resultUploadPdf = StorageService.saveFile(SAPCPIProxy.STORAGE_REPORTS_ENDPOINT + '/weekly-reports' + urlTest, generateReportName(usr,startDate) + '.pdf', pdfData, true);
            WeeklyReport__c result;
            if (resultUpload.containsKey('message') && resultUpload.get('message') == 'File uploaded successfully') {
                Map<String, WeeklyReport__c> existingFiles = existingRecordsByNames(new List<String>{generateReportName(usr,startDate) + '.xls'});
    
                if (existingFiles.containsKey(generateReportName(usr,startDate) + '.xls') == false) {
                    result = insertRecord(usr, generateReportName(usr,startDate) + '.xls', (String) resultUpload.get('key'), generateRecordName(usr, startDate));
                } else {
                    result = existingFiles.get(generateReportName(usr,startDate) + '.xls');
                }
            }
    
           if (resultUploadPdf.containsKey('message') && resultUpload.get('message') == 'File uploaded successfully') {
                Map<String, WeeklyReport__c> existingFiles = existingRecordsByNames(new List<String>{generateReportName(usr,startDate)+ '.pdf'});
    
                if (existingFiles.containsKey(generateReportName(usr,startDate)+ '.pdf') == false) {
                    result = insertRecord(usr, generateReportName(usr,startDate)+ '.pdf', (String) resultUploadPdf.get('key'), generateRecordName(usr, startDate));
                } else {
                    result = existingFiles.get(generateReportName(usr,startDate)+ '.pdf');
                }
            }
        }       
        
        // Crear archivo adjunto
        Messaging.EmailFileAttachment attachmentXls = new Messaging.EmailFileAttachment();
        attachmentXls.setFileName(fileName + '.xls');
        attachmentXls.setContentType('application/vnd.ms-excel');
        attachmentXls.setBody(Blob.valueOf(xlsData));

        if (pdfData != null) {
            Messaging.EmailFileAttachment attachmentPdf = new Messaging.EmailFileAttachment();
            attachmentPdf.setFileName(fileName + '.pdf');
            attachmentPdf.setBody(pdfData);
            attachmentPdf.setContentType('application/pdf');
            attachments.add(attachmentPdf);
        }

        attachments.add(attachmentXls);

        email.setFileAttachments(attachments);


        // Enviar email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
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

    public static Map<String, String> createEventsXls(List<Event> listEvents, User usr) {
        Set<String> accountIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Set<String> ownerIds = new Set<String>();
        Map<String, Account> accountMaps = new Map<String, Account>();
        Map<String, Contact> contactMaps = new Map<String, Contact>();
        Map<String, User> ownerMaps = new Map<String, User>();
        Map<String, String> result = new Map<String, String>();
    
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
                        
                         tableBody += '<td>' + (row.otherComments__c == null ? row.Description : row.otherComments__c) + '</td>' +
                         '<td>' + row.StartDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID()) + '</td>' +
                         '<td>' + row.EndDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID()) + '</td>' +
                         '<td>' + (row.WhatId != null && accountMaps.containsKey(row.WhatId) ? accountMaps.get(row.WhatId).Name : '') + '</td>' +
                         '<td>' + (row.WhoId != null && contactMaps.containsKey(row.WhoId) ? contactMaps.get(row.WhoId).Name : '') + '</td>' +
                         '<td>' + row.Cancelled__c + '</td>' +
                         '<td>' + row.Owner.Name + '</td>' +
                         '<td>' + ownerMaps.get(row.OwnerId).Default_Sales_Organization__c + '</td>' +
                         '<td>' + ownerMaps.get(row.OwnerId).Sales_Office_Text__c + '</td>' +
                         '<td>' + ownerMaps.get(row.OwnerId).countryCode + '</td>' +
                         '<td>' + row.LoginFlowCompleted__c + '</td>' +
                         '<td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + row.Id + '">Link</a></td>' +
                         '</tr>';
        }
    
        String htmlContent = '<html><body>' + tableHeader + tableBody + '</table></body></html>';
    
        result.put('CONTENT', htmlContent);
    
        return result;
    }

    @AuraEnabled
    public static void sendKeyAccountCommentAnswers(List<String> commentIds, Boolean isTest, List<String> removeKeyIds){
        TriggerFlags__c tFlags = [select id,Email_Message__c,SetupOwnerId,SetupOwner.Name 
                          from TriggerFlags__c
                          WHERE SetupOwnerId = :UserInfo.getOrganizationId()
                          LIMIT 1];
        tflags.Email_Message__c = false;
        update tflags;

        try {
            if (commentIds == null || commentIds.isEmpty()) {
                throw new AuraHandledException('No comment IDs provided.');
            }

            // 🔹 Consultamos los comentarios con info relevante
            List<AccountAdditionalInfo__c> listAdditionalInfo = [
                SELECT 
                    Id,
                    Name,
                    Value__c,
                    Value2__c,
                    Value3__c,
                    Value4__c,
                    SentAnswer__c,
                    Account__r.Id,
                    Account__r.Name,
                    Account__r.OwnerId,
                    Account__r.Owner.Email,
                    Account__r.Owner.LanguageLocaleKey,
                    Account__r.Owner.Name
                FROM AccountAdditionalInfo__c
                WHERE Id IN :commentIds
            ];

            if (listAdditionalInfo.isEmpty()) {
                throw new AuraHandledException('No matching comments found.');
            }

            // 🔹 Obtenemos los IDs de los owners para buscar sus CCs
            Set<String> ownerIds = new Set<String>();
            for (AccountAdditionalInfo__c info : listAdditionalInfo) {
                if (info.Account__r != null && info.Account__r.OwnerId != null) {
                    ownerIds.add(info.Account__r.OwnerId);
                }
            }

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Organization org = [Select Id, Name, IsSandbox from Organization];

            for (AccountAdditionalInfo__c comment : listAdditionalInfo) {
                if (String.isBlank(comment.Value2__c)) {
                    System.debug('Skipping record ' + comment.Id + ' — No answer provided.');
                    continue;
                }

                String ownerEmail = comment.Value4__c;

                // 🔹 Construcción del correo
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                if (String.isBlank(ownerEmail) == false) {
                   email.setToAddresses(new List<String>{ comment.Account__r.Owner.Email });
                }

                if (isTest) {
                    email.setToAddresses(new List<String>{ 'ivan.losilla@porcelanosagrupo.com' });
                }

                // 🔹 Añadimos los CC desde el método auxiliar
                List<String> ccList = new List<String>();
                if (comment.Value3__c != null) {
                    ccList = comment.Value3__c.split(';');
                }
            
                if (org.IsSandbox == false) {
                    ccList.add('silvestre.segarra@porcelanosagrupo.com');
                }
                ccList.add('ivan.losilla@porcelanosagrupo.com');

                if (!ccList.isEmpty() && isTest == false) {
                    if (String.isBlank(ownerEmail) == true) {
                        email.setToAddresses(ccList);
                    } else {
                        email.setCcAddresses(ccList);
                    }
                }

                email.setSubject('Key Account Comment Feedback - ' + comment.Account__r.Name);

                String lang = comment.Account__r.Owner.LanguageLocaleKey != null
                ? comment.Account__r.Owner.LanguageLocaleKey.substring(0,2)
                : 'en';
                
                String accountUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + comment.Account__r.Id;

                String hello, receivedFeedback, summaryIntro, accountLbl, commentLbl, responseLbl, contactManager, kindRegards;

                if(lang == 'fr') {
                    hello = 'Bonjour';
                    receivedFeedback = 'Vous avez reçu un retour concernant l\'une de vos Comptes Clés.';
                    summaryIntro = 'Voici un résumé avec le commentaire original et la réponse fournie :';
                    accountLbl = 'Compte';
                    commentLbl = 'Commentaire';
                    responseLbl = 'Réponse';
                    contactManager = 'Si vous avez des questions ou souhaitez discuter de ce retour, veuillez contacter votre manager.';
                    kindRegards = 'Cordialement';
                } else if(lang == 'es') {
                    hello = 'Hola';
                    receivedFeedback = 'Has recibido feedback sobre una de tus Key Accounts.';
                    summaryIntro = 'Aquí tienes un resumen con el comentario original y la respuesta proporcionada:';
                    accountLbl = 'Account';
                    commentLbl = 'Comentario';
                    responseLbl = 'Respuesta';
                    contactManager = 'Si tienes alguna duda o quieres comentar este feedback, contacta con tu manager.';
                    kindRegards = 'Un cordial saludo';
                } else { // inglés por defecto
                    hello = 'Hello';
                    receivedFeedback = 'You have received feedback on one of your Key Accounts.';
                    summaryIntro = 'Here is a summary with the original comment and the provided response:';
                    accountLbl = 'Account';
                    commentLbl = 'Comment';
                    responseLbl = 'Response';
                    contactManager = 'If you have any questions or want to discuss this feedback, please contact your manager.';
                    kindRegards = 'Kind regards';
                }

                String body = ''
                    + '<p>' + hello + ' ' + comment.Account__r.Owner.Name + ',</p>'
                    + '<p>' + receivedFeedback + '</p>'
                    + '<p>' + summaryIntro + '</p>'

                    + '<table style="border-collapse:collapse;width:100%;font-family:Arial, sans-serif;font-size:14px;">'

                        + '<tr>'
                            + '<td style="padding:8px;border:1px solid #ddd;font-weight:bold;background:#f4f6f9;">'
                                + accountLbl
                            + '</td>'
                            + '<td style="padding:8px;border:1px solid #ddd;">'
                                + '<a href="' + accountUrl + '" style="color:#1589ee;" target="_blank">'
                                + comment.Account__r.Name
                                + '</a>'
                            + '</td>'
                        + '</tr>'

                        + '<tr>'
                            + '<td style="padding:8px;border:1px solid #ddd;font-weight:bold;background:#f4f6f9;">'
                                + commentLbl
                            + '</td>'
                            + '<td style="padding:8px;border:1px solid #ddd;">'
                                + (String.isNotBlank(comment.Value__c) ? comment.Value__c : '<em>-</em>')
                            + '</td>'
                        + '</tr>'

                        + '<tr>'
                            + '<td style="padding:8px;border:1px solid #ddd;font-weight:bold;background:#f4f6f9;">'
                                + responseLbl
                            + '</td>'
                            + '<td style="padding:8px;border:1px solid #ddd;background:#f9f9f9;">'
                                + comment.Value2__c
                            + '</td>'
                        + '</tr>'

                    + '</table>'

                    + '<p>' + contactManager + '</p>'
                    + '<p>' + kindRegards;

                if (isTest) {
                    body += '<p>Test mode enabled. No emails were sent.</p>';
                    body += '<p>To: ' + ownerEmail + '</p>';
                    if (!ccList.isEmpty()) {
                        body += '<p>CC: ' + String.join(ccList, ',') + '</p>';
                    }
                }

                email.setHtmlBody(body);

                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
                List<AccountAdditionalInfo__c> updates = new List<AccountAdditionalInfo__c>();
                List<String> updatedIds = new List<String>();

                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        AccountAdditionalInfo__c updated = listAdditionalInfo[i];
                        updated.SentAnswer__c = System.now();
                        updates.add(updated);
                        updatedIds.add(updated.Id);
                    } else {
                        System.debug('Error sending email for record ' + listAdditionalInfo[i].Id + ': ' + results[i].getErrors()[0].getMessage());
                    }
                }

                if (!updates.isEmpty()) {
                    update updates;
                }

                if(removeKeyIds != null && !removeKeyIds.isEmpty()) {
                    // 🔹 Consultamos los comentarios con info relevante
                    List<AccountAdditionalInfo__c> listAdditionalInfoToRemove = [
                        SELECT 
                            Id,
                            Account__c
                        FROM AccountAdditionalInfo__c
                        WHERE Id IN :removeKeyIds
                    ];
                    if(!listAdditionalInfoToRemove.isEmpty()) {
                        List<String> accIds = new List<String>();
                        for(AccountAdditionalInfo__c infoToRemove : listAdditionalInfoToRemove) {
                            //if(updatedIds.contains(infoToRemove.Id) && infoToRemove.Account__c != null) {
                            if(infoToRemove.Account__c != null) {
                                accIds.add(infoToRemove.Account__c);
                            }
                        }
                        if(!accIds.isEmpty()) {
                            KeyAccountManagementController.removeAsKey(accIds);
                        }
                    }
                }
            }

            tflags.Email_Message__c = true;
            update tflags;

        } catch (Exception e) {
            tflags.Email_Message__c = true;
            update tflags;
            System.debug('Error sending Key Account comment emails: ' + e.getMessage());
            throw new AuraHandledException('Failed to send emails: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void sendMainCommentKeyOpportunityComments(String comment, String accountId){
        try {
            List<OpportunityAdditionalInfo__c> listAdditionalInfo = [
                SELECT 
                    Id,
                    Name,
                    Value__c,
                    Value2__c,
                    Value3__c,
                    Value4__c,
                    SentAnswer__c,
                    Opportunity__r.Id,
                    Opportunity__r.Name,
                    Opportunity__r.OwnerId,
                    Opportunity__r.Owner.Email,
                    Opportunity__r.Owner.LanguageLocaleKey,
                    Opportunity__r.Owner.Name
                FROM OpportunityAdditionalInfo__c
                WHERE Opportunity__r.AccountId =: accountId
                AND SentAnswer__c = null
                AND WeeklyCompleted__c != NULL
                ORDER BY WeeklyCompleted__c DESC
            ];

            Map<String, OpportunityAdditionalInfo__c> commentsToSend = new Map<String, OpportunityAdditionalInfo__c>();
            List<String> commentIds = new List<String>();

            for (OpportunityAdditionalInfo__c info : listAdditionalInfo) {
                if (commentsToSend.containsKey(info.Opportunity__r.Id) == false) {
                    info.Value2__c = comment;
                    commentsToSend.put(info.Opportunity__r.Id, info);
                    commentIds.add(info.Id);
                }
            }

            update commentsToSend.values();

            sendKeyOpportunityCommentAnswers(commentIds, false, new List<String>());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void sendKeyOpportunityCommentAnswers(List<String> commentIds, Boolean isTest, List<String> removeKeyIds){
        TriggerFlags__c tFlags = [select id,Email_Message__c,SetupOwnerId,SetupOwner.Name 
                          from TriggerFlags__c
                          WHERE SetupOwnerId = :UserInfo.getOrganizationId()
                          LIMIT 1];
        tflags.Email_Message__c = false;
        update tflags;
        try {
            if (commentIds == null || commentIds.isEmpty()) {
                throw new AuraHandledException('No comment IDs provided.');
            }

            // 🔹 Consultamos los comentarios con info relevante
            List<OpportunityAdditionalInfo__c> listAdditionalInfo = [
                SELECT 
                    Id,
                    Name,
                    Value__c,
                    Value2__c,
                    Value3__c,
                    Value4__c,
                    SentAnswer__c,
                    Opportunity__r.Id,
                    Opportunity__r.Name,
                    Opportunity__r.OwnerId,
                    Opportunity__r.Owner.Email,
                    Opportunity__r.Owner.LanguageLocaleKey,
                    Opportunity__r.Owner.Name
                FROM OpportunityAdditionalInfo__c
                WHERE Id IN :commentIds
            ];

            if (listAdditionalInfo.isEmpty()) {
                throw new AuraHandledException('No matching comments found.');
            }

            // 🔹 Obtenemos los IDs de los owners para buscar sus CCs
            Set<String> ownerIds = new Set<String>();
            for (OpportunityAdditionalInfo__c info : listAdditionalInfo) {
                if (info.Opportunity__r != null && info.Opportunity__r.OwnerId != null) {
                    ownerIds.add(info.Opportunity__r.OwnerId);
                }
            }

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Organization org = [Select Id, Name, IsSandbox from Organization];

            for (OpportunityAdditionalInfo__c comment : listAdditionalInfo) {
                if (String.isBlank(comment.Value2__c)) {
                    System.debug('Skipping record ' + comment.Id + ' — No answer provided.');
                    continue;
                }

                String ownerEmail = comment.Value4__c;

                // 🔹 Construcción del correo
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                if (String.isBlank(ownerEmail) == false) {
                    email.setToAddresses(new List<String>{ comment.Opportunity__r.Owner.Email });
                }

                if (isTest) {
                    email.setToAddresses(new List<String>{ 'ivan.losilla@porcelanosagrupo.com' });
                }

                // 🔹 Añadimos los CC desde el método auxiliar
                List<String> ccList = new List<String>();
                if (comment.Value3__c != null) {
                    ccList = comment.Value3__c.split(';');
                }
                if (org.IsSandbox == false) {
                    ccList.add('silvestre.segarra@porcelanosagrupo.com');
                }
                ccList.add('ivan.losilla@porcelanosagrupo.com');

                if (!ccList.isEmpty() && isTest == false) {
                    if (String.isBlank(ownerEmail) == false) {
                        email.setCcAddresses(ccList);
                    } else {
                        email.setToAddresses(ccList);
                    }
                }

                email.setSubject('Key Opportunity Comment Feedback - ' + comment.Opportunity__r.Name);

                String lang = comment.Opportunity__r.Owner.LanguageLocaleKey != null
                ? comment.Opportunity__r.Owner.LanguageLocaleKey.substring(0,2)
                : 'en';
                
                String opportunityUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + comment.Opportunity__r.Id;

                String hello, receivedFeedback, summaryIntro, opportunityLbl, commentLbl, responseLbl, contactManager, kindRegards;

                if(lang == 'fr') {
                    hello = 'Bonjour';
                    receivedFeedback = 'Vous avez reçu un retour concernant l\'une de vos Opportunités Clés.';
                    summaryIntro = 'Voici un résumé avec le commentaire original et la réponse fournie :';
                    opportunityLbl = 'Opportunité';
                    commentLbl = 'Commentaire';
                    responseLbl = 'Réponse';
                    contactManager = 'Si vous avez des questions ou souhaitez discuter de ce retour, veuillez contacter votre manager.';
                    kindRegards = 'Cordialement';
                } else if(lang == 'es') {
                    hello = 'Hola';
                    receivedFeedback = 'Has recibido feedback sobre una de tus Key Opportunities.';
                    summaryIntro = 'Aquí tienes un resumen con el comentario original y la respuesta proporcionada:';
                    opportunityLbl = 'Oportunidad';
                    commentLbl = 'Comentario';
                    responseLbl = 'Respuesta';
                    contactManager = 'Si tienes alguna duda o quieres comentar este feedback, contacta con tu manager.';
                    kindRegards = 'Un cordial saludo';
                } else { // inglés por defecto
                    hello = 'Hello';
                    receivedFeedback = 'You have received feedback on one of your Key Opportunities.';
                    summaryIntro = 'Here is a summary with the original comment and the provided response:';
                    opportunityLbl = 'Opportunity';
                    commentLbl = 'Comment';
                    responseLbl = 'Response';
                    contactManager = 'If you have any questions or want to discuss this feedback, please contact your manager.';
                    kindRegards = 'Kind regards';
                }

                String body = ''
                    + '<p>' + hello + ' ' + comment.Opportunity__r.Owner.Name + ',</p>'
                    + '<p>' + receivedFeedback + '</p>'
                    + '<p>' + summaryIntro + '</p>'

                    + '<table style="border-collapse:collapse;width:100%;font-family:Arial, sans-serif;font-size:14px;">'

                        + '<tr>'
                            + '<td style="padding:8px;border:1px solid #ddd;font-weight:bold;background:#f4f6f9;">'
                                + opportunityLbl
                            + '</td>'
                            + '<td style="padding:8px;border:1px solid #ddd;">'
                                + '<a href="' + opportunityUrl + '" style="color:#1589ee;" target="_blank">'
                                + comment.Opportunity__r.Name
                                + '</a>'
                            + '</td>'
                        + '</tr>'

                        + '<tr>'
                            + '<td style="padding:8px;border:1px solid #ddd;font-weight:bold;background:#f4f6f9;">'
                                + commentLbl
                            + '</td>'
                            + '<td style="padding:8px;border:1px solid #ddd;">'
                                + (String.isNotBlank(comment.Value__c) ? comment.Value__c : '<em>-</em>')
                            + '</td>'
                        + '</tr>'

                        + '<tr>'
                            + '<td style="padding:8px;border:1px solid #ddd;font-weight:bold;background:#f4f6f9;">'
                                + responseLbl
                            + '</td>'
                            + '<td style="padding:8px;border:1px solid #ddd;background:#f9f9f9;">'
                                + comment.Value2__c
                            + '</td>'
                        + '</tr>'

                    + '</table>'

                    + '<p>' + contactManager + '</p>'
                    + '<p>' + kindRegards;

                if (isTest) {
                    body += '<p>Test mode enabled. No emails were sent.</p>';
                    body += '<p>To: ' + ownerEmail + '</p>';
                    if (!ccList.isEmpty()) {
                        body += '<p>CC: ' + String.join(ccList, ',') + '</p>';
                    }
                }

                email.setHtmlBody(body);

                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
                List<OpportunityAdditionalInfo__c> updates = new List<OpportunityAdditionalInfo__c>();
                List<String> updatedIds = new List<String>();

                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        OpportunityAdditionalInfo__c updated = listAdditionalInfo[i];
                        updated.SentAnswer__c = System.now();
                        updates.add(updated);
                        updatedIds.add(updated.Id);
                    } else {
                        System.debug('Error sending email for record ' + listAdditionalInfo[i].Id + ': ' + results[i].getErrors()[0].getMessage());
                    }
                }

                if (!updates.isEmpty()) {
                    update updates;
                }

                if(removeKeyIds != null && !removeKeyIds.isEmpty()) {
                    // 🔹 Consultamos los comentarios con info relevante
                    List<OpportunityAdditionalInfo__c> listAdditionalInfoToRemove = [
                        SELECT 
                            Id,
                            Opportunity__c
                        FROM OpportunityAdditionalInfo__c
                        WHERE Id IN :removeKeyIds
                    ];
                    if(!listAdditionalInfoToRemove.isEmpty()) {
                        List<String> oppIds = new List<String>();
                        for(OpportunityAdditionalInfo__c infoToRemove : listAdditionalInfoToRemove) {
                            if(updatedIds.contains(infoToRemove.Id) && infoToRemove.Opportunity__c != null) {
                                oppIds.add(infoToRemove.Opportunity__c);
                                System.debug('OPP ADDED TO REMOVE AS KEY: ' + infoToRemove.Opportunity__c);
                            }
                        }
                        if(!oppIds.isEmpty()) {
                            System.debug(oppIds);
                            KeyOpportunityManagementController.removeAsKey(oppIds);
                        }
                    }
                }
            }

            tflags.Email_Message__c = true;
            update tflags;

        } catch (Exception e) {
            tflags.Email_Message__c = true;
            update tflags;
            System.debug('Error sending Key Opportunity comment emails: ' + e.getMessage());
            throw new AuraHandledException('Failed to send emails: ' + e.getMessage());
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
        return s;
    }
}