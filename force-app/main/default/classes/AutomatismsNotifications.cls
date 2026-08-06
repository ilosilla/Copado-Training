/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			11-07-2019
Description:    Maneja el envio de notificaciones y emails cuando se generan errores de SAP
Test Class:     AutomatismsNotifications_Test
History
<Date>            <Author>              <Change Description>

-----------------------------------------------------------------------------------------*/

public class AutomatismsNotifications { 
    
    private static final Schema.SObjectType salesRelType = Schema.Sales_Relationship__c.getSObjectType();
    private static final Schema.SObjectType oppContactRoleType = Schema.OpportunityContactRole.getSObjectType();
    private static final String accountObjectName = Schema.Account.getSObjectType().getDescribe().getLabel();
    private static final String oppObjectName = Schema.Opportunity.getSObjectType().getDescribe().getLabel();
    
    public static void generateNotifications(Id chatterGroupId, Id userId, EmailTemplate emailTemplate,
                                             sObject affectedRecord, String errorMessage, List<FeedItem> postToInsert, 
                                             List<Messaging.SingleEmailMessage> emailList, List<CustomNotification> customNotifList){
                                                 // Genera notificaciones de error de todos los tipos. Chatter, User Notification, Email.
                                                 
        if(chatterGroupId != null){
            postToInsert.add(createChatterPost(chatterGroupId, affectedRecord, errorMessage));
        }
        
        if(userId != null){
            //postToInsert.add(createUserFeed(userId, affectedRecord, errorMessage == null));
            customNotifList.add(createAutomationNotification(userId, affectedRecord, errorMessage == null));
        }
        
        if(emailTemplate != null && System.isFuture() && errorMessage != null){
            emailList.add(createEmail(emailTemplate, affectedRecord, errorMessage));
        }
        
    }
    
    // Genera una notificacion de error para el grupo de chatter a cargo de SAP
    public static FeedItem createChatterPost(Id chatterGroupId, sObject affectedRecord, String errorMessage){
        //IsRichText = true y Type = TextPost para que el post pueda tener etiquetas HTML
        
        return new FeedItem(
            ParentId = chatterGroupId,
            Title = Label.Error_during_SAP_Synchronization,
            IsRichText = true,
            Type = 'TextPost',
            Body = formatChatterMessage(affectedRecord, errorMessage)
        );
        
    }
    
    // Formatea el mensaje de error del post de chatter utilizado para notificar errores.
    public static String formatChatterMessage(SObject affectedRecord, String errorMessage){
        String parentObjectName, recordName, recordId;

        if(affectedRecord.getSObjectType() == oppContactRoleType){
            OpportunityContactRole oppContactRole = (OpportunityContactRole) affectedRecord;
            recordId = oppContactRole.OpportunityId;
            parentObjectName = oppObjectName;
        } else if(affectedRecord.getSObjectType() == salesRelType){
            Sales_Relationship__c salesRel = (Sales_Relationship__c) affectedRecord;
            recordName = salesRel.Name;
            recordId = salesRel.Account_Org__c;
            parentObjectName = accountObjectName;
        }
        
        return '<b>' + Label.Error_during_SAP_Synchronization + '</b>: ' + Label.Error_Trying_to_Send_The_Record + '.<p></p><u><b>' + Label.Record_Name + '</b></u>: ' + 
            recordName + '<p></p><u><b>Error</b></u>: ' + errorMessage + '<p>&nbsp;</p><a href="' + URL.getSalesforceBaseUrl().toExternalForm() +
            '/lightning/r/' + parentObjectName + '/' + recordId + '/view' + '">' + Label.See_detailed_info + '.' + '</a>';
        
    }
    
    // Contruye el mail de notificacion de errores para las automatizaciones
    public static Messaging.SingleEmailMessage createEmail(EmailTemplate emailTemplate, sObject affectedRecord, String errorMessage){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        email.setTargetObjectId(UserInfo.getUserId());
        email.setHtmlBody(formatEmailMessage(affectedRecord, errorMessage, emailTemplate.HtmlValue));
        email.setSubject(emailTemplate.Subject);
        email.setTreatTargetObjectAsRecipient(true);
        email.setSaveAsActivity(false);
        
        return email;
    }
    
    // Reemplaza valores en el cuerpo de una plantilla de Mail HTML basandose en el registro affectedRecord
    public static String formatEmailMessage(sObject affectedRecord, String errorMessage, String HtmlValue){
        String parentObjectName, recordName, recordId;
        String formatedHTML = HtmlValue;

        if(affectedRecord.getSObjectType() == oppContactRoleType){
            OpportunityContactRole oppContactRole = (OpportunityContactRole) affectedRecord;
            recordName = oppContactRole.Contact.Name;
            recordId = oppContactRole.OpportunityId;
            parentObjectName = oppObjectName;
        } else if(affectedRecord.getSObjectType() == salesRelType){
            Sales_Relationship__c salesRel = (Sales_Relationship__c) affectedRecord;
            recordName = salesRel.Name;
            recordId = salesRel.Account_Org__c;
            parentObjectName = accountObjectName;
        }
        
        formatedHTML = formatedHTML.replace('{!errorDetails}', Label.Error_Details);
        formatedHTML = formatedHTML.replace('{!title}', Label.Error_during_SAP_Synchronization);
        formatedHTML = formatedHTML.replace('{!description}', Label.Error_Trying_to_Send_The_Record);
        formatedHTML = formatedHTML.replace('{!detailedInfo}', Label.See_detailed_info);
        formatedHTML = formatedHTML.replace('{!recordName}', Label.dict_name);
        formatedHTML = formatedHTML.replace('{!record.Name}', recordName);
        formatedHTML = formatedHTML.replace('{!errorMessage}', errorMessage);
        formatedHTML = formatedHTML.replace('{!recordLink}', URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + parentObjectName + '/' + recordId + '/view');
        
        return formatedHTML;
    }
    
    public static CustomNotification createAutomationNotification(Id userId, sObject affectedRecord, Boolean success){
        String recordName, recordId;
        
        if(affectedRecord.getSObjectType() == oppContactRoleType){
            OpportunityContactRole oppContactRole = (OpportunityContactRole) affectedRecord;
            recordName = oppContactRole.Contact.Name;
            recordId = oppContactRole.OpportunityId;
            
        } else if(affectedRecord.getSObjectType() == salesRelType){
            Sales_Relationship__c salesRel = (Sales_Relationship__c) affectedRecord;
            recordName = salesRel.Name;
            recordId = salesRel.Account_Org__c;
            
        }
        
        String body = affectedRecord.getSObjectType().getDescribe().getLabel() + ' "' + recordName + '"', 
            title = success ? Label.Success_during_SAP_Synchronization : Label.Error_during_SAP_Synchronization;
        
        body += '. ' + Label.Click_this_notification +  '.';
        
        return createUserNotification(userId, recordId, title, body);
    }
    
    public static CustomNotification createUserNotification(Id userId, String targetId, String title, String body){
        return new CustomNotification(targetId)
            .type('SAP_Automations_Custom_Notification')
            .title(title)
            .body(body)
            .recipients(new List<Id>{userId});
    }
    
    public static void sendCustomNotifications(List<CustomNotification> customNotifList){
        if(!customNotifList.isEmpty()){
            for(CustomNotification cN : customNotifList){
                Map<String, Object> result = cN.send();
                if(result.containsKey('error')){
                    System.debug('Error sending the notification: ' + result.get('error'));
                } else {
                    System.debug('Notification successfully sent.');
                }
            }
        }
    }
    
    public static void insertFeedItems(List<FeedItem> postToInsert){
        
        if(!postToInsert.isEmpty()){
            
            Database.SaveResult[] postResultList = Database.insert(postToInsert, false);
            
            for (Database.SaveResult sr : postResultList){
                
                if (sr.isSuccess()){
                    System.debug('Successfully inserted Feed Item with ID: ' + sr.getId());
                    
                }
                else {
                    // Operation failed, so get all errors                
                    System.debug('Feed Item Insert Error: ');
                    
                    for(Database.Error err : sr.getErrors()) {    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        
    }
    
    public static void sendEmails(List<Messaging.SingleEmailMessage> emailList){
        if(!emailList.isEmpty()){
            Messaging.SendEmailResult [] emailResults = Messaging.sendEmail(emailList, false);
            
            for (Messaging.SendEmailResult eR : emailResults) {
                
                if (eR.isSuccess()) {
                    System.debug('Successfull email delivery');
                } else {
                    
                    for( Messaging.SendEmailError err : eR.getErrors()) {
                        System.debug('The following error has occurred while trying to send an email: ' + err.getTargetObjectId());
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
}