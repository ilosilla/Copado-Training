global class DashboardEmailAlert_Batch implements Database.Batchable<sObject>, Database.Stateful{
    
    global String error = '';
    global Boolean status = true; 
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // The users stored in the Weekly_Activity_Exception__c should not receive this email.
        Set<Id> userIdsException = new Set<Id>();
        
        for(Weekly_Activity_Exception__c wae : [SELECT User__c FROM Weekly_Activity_Exception__c]){
            userIdsException.add(wae.User__c);
        }
        
        String query = 'SELECT Id, LanguageLocaleKey FROM User WHERE IsActive = true AND Id NOT IN : userIdsException';
        // The number of records should be limited to avoid hitting the batch size limit for test classes
        query += Test.isRunningTest() ? ' limit 20' : '';
        
        return Database.getQueryLocator(
            query
        );
    }
    
    global void execute(Database.BatchableContext bc, List<User> scope) {
        
        EmailTemplate templateUK, templateFR, templateES, templateIT; Boolean templateError = false;        
        try{
            templateUK = [SELECT Id,Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'weekly_activity'];
            templateFR = [SELECT Id,Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'weekly_activity_FR'];
            templateES = [SELECT Id,Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'weekly_activity_ES'];
            templateIT = [SELECT Id,Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'weekly_activity_IT'];
        } catch(Exception ex){
            System.debug('Failed to locate the email templates with error: ' + ex.getMessage());
            error = 'Failed to locate the email template with error: ' + ex.getMessage();
            status = false;
            templateError = true;
        }
        
        if(!templateError){
            
            List<Id> franceUsers = new List<Id>();
            List<Id> UKUsers = new List<Id>();
            List<Id> ESUsers = new List<Id>();
            List<Id> ITUsers = new List<Id>();
            
            for(User u : scope){
                switch on u.LanguageLocaleKey {
                    when 'en_US' {
                        UKUsers.add(u.Id);                        
                    }
                    when 'fr' {
                        franceUsers.add(u.Id);                        
                    }
                    when 'es' {
                        ESUsers.add(u.Id);                        
                    }
                    when 'it' {
                        ITUsers.add(u.Id);                        
                    }
                    when else {
                        UKUsers.add(u.Id);                        
                    }   
                }
            }
            
            Messaging.MassEmailMessage  mailUK, mailFR, mailES, mailIT;
            
            if( templateUK != null && !UKUsers.isEmpty() ) {
                mailUK = new Messaging.MassEmailMessage();
                mailUK.setTemplateId(templateUK.Id);
                mailUK.setTargetObjectIds(UKUsers);
                mailUK.setSaveAsActivity(false);
            }
            
            if( templateFR != null && !franceUsers.isEmpty() ) {
                mailFR = new Messaging.MassEmailMessage();
                mailFR.setTemplateId(templateFR.Id);
                mailFR.setTargetObjectIds(franceUsers);
                mailFR.setSaveAsActivity(false);
            }

            if( templateES != null && !ESUsers.isEmpty() ) {
                mailES = new Messaging.MassEmailMessage();
                mailES.setTemplateId(templateES.Id);
                mailES.setTargetObjectIds(ESUsers);
                mailES.setSaveAsActivity(false);
            }

            if( templateIT != null && !ITUsers.isEmpty() ) {
                mailIT = new Messaging.MassEmailMessage();
                mailIT.setTemplateId(templateIT.Id);
                mailIT.setTargetObjectIds(ITUsers);
                mailIT.setSaveAsActivity(false);
            }
            
            List<Messaging.MassEmailMessage> toSendList = new List<Messaging.MassEmailMessage>();
            
            if( mailUK != null ){ toSendList.add(mailUK); }
            
            if( mailFR != null ){ toSendList.add(mailFR); }

            if( mailES != null ){ toSendList.add(mailES); }

            if( mailIT != null ){ toSendList.add(mailIT); }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(toSendList);
            for(Messaging.SendEmailResult r : results){
                if (r.success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' + r.errors[0].message);
                    error += r.errors[0].message;
                    status = false;
                }
            }
            
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,ExtendedStatus, TotalJobItems
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        
        //Send an email to the User after your batch completes
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setSaveAsActivity(false);
        mail.setTreatTargetObjectAsRecipient(true);
        mail.setSubject('Weekly activity dashboard errors');
        
        String plainTextBody = 'Batch Job Id ' + bc.getJobId() + '\n';
        
        if(!status || job.NumberOfErrors > 0 || job.Status == 'Failed'){
            plainTextBody += error;
            plainTextBody += '\n' + job.ExtendedStatus;
            mail.setPlainTextBody(plainTextBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }
    
}