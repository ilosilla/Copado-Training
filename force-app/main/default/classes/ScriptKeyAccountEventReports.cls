/**
* @author Ivan Losilla
* @date April 2025
* @group Scripts
* @description Script de envío de reports de key Accounts
* @test ScriptKeyAccountEventReportsTest
*/
global class ScriptKeyAccountEventReports Implements Schedulable {

    private Map<String, List<String>> emailAddressesByRegion= new Map<String, List<String>>{
        'FR' => new List<String>{'silvestre.segarra@porcelanosagrupo.com.sandbox','psimarro@porcelanosa.com.sandbox','ivan.losilla@porcelanosagrupo.com'},
        'GB' => new List<String>{'silvestre.segarra@porcelanosagrupo.com.sandbox','jbodi@porcelanosa.com.sandbox','ivan.losilla@porcelanosagrupo.com'},
        'US' => new List<String>{'silvestre.segarra@porcelanosagrupo.com.sandbox','mprior@porcelanosa-usa.com.sandbox','ivan.losilla@porcelanosagrupo.com'}
    };

    public ScriptKeyAccountEventReports(Map<String, List<String>> emailsByRegion){
        this.emailAddressesByRegion = emailsByRegion;
    }

    public ScriptKeyAccountEventReports(){}

    global void execute(SchedulableContext sc)
        {
            SendEmails();
        }

    public void SendEmails()
    {

        if (!Test.isRunningTest() && ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
            for (String region : this.emailAddressesByRegion.keySet()) {
                List<String> cleaned = new List<String>();
                for (String email : this.emailAddressesByRegion.get(region)) {
                    cleaned.add(email.replace('.sandbox', ''));
                }
                this.emailAddressesByRegion.put(region, cleaned);
            }
        }

        Date startDate = Date.today().toStartOfWeek();
        Date endDate = startDate.addDays(6);

        User reportUser = new UsersSelector().selectById('0051r000009EJMgAAO');

        Map<String, Set<String>> orgsByRegion = new Map<String, Set<String>>{
            'GB' => new Set<String>{'502','511','514','515','516','517','518'},
            'FR' => new Set<String>{'225','226','227','228','229','230','231','232'},
            'US' => new Set<String>{'602','604','603','605','606','608','650'}
        };

        Map<String, List<Event>> completedEventsByRegion = new Map<String, List<Event>>{
            'FR' => new List<Event>(),
            'GB' => new List<Event>(),
            'US' => new List<Event>()
        };

        Map<String, List<Event>> incompletedEventsByRegion = new Map<String, List<Event>>{
            'FR' => new List<Event>(),
            'GB' => new List<Event>(),
            'US' => new List<Event>()
        };

        Map<String, User> userMap = new Map<String, User>();
        for (User u : [SELECT Id, Default_Sales_Organization__c FROM User WHERE IsActive = true]) {
            userMap.put(u.Id, u);
        }

        Set<String> keyEventIds = new Set<String>();
        for (Follow__c f : [SELECT ActivityId__c FROM Follow__c WHERE RecordType.Name = 'Event' AND Owner.Alias IN ('ssega', 'MPrio')]) {
            keyEventIds.add(f.ActivityId__c);
        }

        List<Event> completedEvents = [
            SELECT Id, Subject,Description, startDateTime, endDateTime,whatId, WhoId,cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c
            FROM Event
            WHERE StartDateTime >= :startDate AND StartDateTime <= :endDate
            AND (LoginFlowCompleted__c != NULL OR (WhatId != NULL AND WhoId != NULL))
            AND (NOT Subject LIKE '%[Internal]%')
            AND Type != 'Non Commercial'
            AND IsPrivate = false
            AND Id IN :keyEventIds
        ];

        List<Event> incompletedEvents = [
            SELECT Id, Subject,Description, startDateTime, endDateTime,whatId, WhoId,cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c
            FROM Event
            WHERE StartDateTime >= :startDate AND StartDateTime <= :endDate
            AND LoginFlowCompleted__c = NULL
            AND (WhatId = NULL OR WhoId = NULL OR Type = NULL)
            AND (NOT Subject LIKE '%[Internal]%')
            AND Type != 'Non Commercial'
            AND IsPrivate = false
            AND Id IN :keyEventIds
        ];

        for (Event e : completedEvents) {
            if (userMap.containsKey(e.OwnerId)) {
                User owner = userMap.get(e.OwnerId);
                for (String region : orgsByRegion.keySet()) {
                    if (orgsByRegion.get(region).contains(owner.Default_Sales_Organization__c)) {
                        completedEventsByRegion.get(region).add(e);
                    }
                }
            }
        }

        for (Event e : incompletedEvents) {
            if (userMap.containsKey(e.OwnerId)) {
                User owner = userMap.get(e.OwnerId);
                for (String region : orgsByRegion.keySet()) {
                    if (orgsByRegion.get(region).contains(owner.Default_Sales_Organization__c)) {
                        incompletedEventsByRegion.get(region).add(e);
                    }
                }
            }
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for (String region : orgsByRegion.keySet()) {
            emailsToSend.add(prepareEmail(region, completedEventsByRegion.get(region), incompletedEventsByRegion.get(region), this.emailAddressesByRegion.get(region), reportUser));
        }

        Messaging.sendEmail(emailsToSend);
        System.debug('✅ Emails enviados correctamente.');
        }

        private Messaging.SingleEmailMessage prepareEmail(String region, List<Event> completed, List<Event> incompleted, List<String> toAddresses, User usr) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
    
            List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'salesforce@porcelanosagrupo.com'];
            if (!owea.isEmpty()) {
                email.setOrgWideEmailAddressId(owea[0].Id);
                email.setUseSignature(false);
            }
    
            email.setSubject(region + ' Key Accounts - Event reports');
            email.setHtmlBody('Please find attached the weekly report summarizing all the managed events of key Accounts registered in Salesforce');
    
            String xlsDataCompleted = ReportsHelper.createEventsXls(completed, usr).get('CONTENT');
            String xlsDataInCompleted = ReportsHelper.createEventsXls(incompleted, usr).get('CONTENT');
    
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            attachments.add(createXlsAttachment('Completed events.xls', xlsDataCompleted));
            attachments.add(createXlsAttachment('Incompleted events.xls', xlsDataInCompleted));
    
            email.setFileAttachments(attachments);
            return email;
        }
    
        private Messaging.EmailFileAttachment createXlsAttachment(String filename, String content) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(filename);
            attachment.setContentType('application/vnd.ms-excel');
            attachment.setBody(Blob.valueOf(content));
            return attachment;
        }
}