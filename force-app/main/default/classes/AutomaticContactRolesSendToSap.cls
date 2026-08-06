/**
* @author Ivan Losilla
* @date January 2022
* @group SAP
* @description Manage send the Contact Roles of Opportunities to SAP
*/
public class AutomaticContactRolesSendToSap {

    public static void manageSendToSap(List<OpportunityContactRole> contactRoles){
        List<Id> contactRoleIdList = new List<Id>();
        for (OpportunityContactRole elem : contactRoles) {
            contactRoleIdList.add(elem.Id);
        }
        if(!contactRoleIdList.isEmpty()){
            sendToSAPFuture(contactRoleIdList);
        }
    }
    
    @future(callout=true)
    public static void sendToSAPFuture(List<Id> contactRoleIdList){
        SendToSAP(contactRoleIdList);
    }
    
    public static void sendToSAP(List<Id> contactRoleIdList){
        List<OpportunityContactRole> contactRoles = [SELECT Id, OpportunityId, Account__c, Contact.Name FROM OpportunityContactRole WHERE Id IN: contactRoleIdList];                                        
        
        if(!contactRoles.isEmpty()){
            Set<Id> oppIds =  new Set<Id>();
            
            for( OpportunityContactRole contactRole : contactRoles ){
                oppIds.add(contactRole.OpportunityId);
            }
            
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name, AccountId, Sales_Org__c,SalesProgram__c, Dist_Channel__c, StageName, IsGeneric__c, CloseDate,
                                                                    (SELECT Id, ContactId,Account__c, Role FROM OpportunityContactRoles)
                                                                    FROM Opportunity
                                                                    WHERE Id IN: oppIds]);
            
            Map<Id, Map<String,Object>> responseMap = new Map<Id, Map<String,Object>>();
            
            for(OpportunityContactRole contactRole : contactRoles){
                responseMap.put(contactRole.Id, SendRequest(oppMap.get(contactRole.OpportunityId)));
            }
            
            String groupName;
            Id chatterGroupId;
            EmailTemplate emailTemplate;
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            List<FeedItem> postToInsert = new List<FeedItem>();
            List<CustomNotification> customNotifList = new List<CustomNotification>();
            
            try{
                groupName = Test.isRunningTest() ? 'test group name' : [SELECT Group_Name__c FROM Sap_Errors_Group_Config__mdt WHERE DeveloperName = 'Porcelanosa_Group'].Group_Name__c;
                emailTemplate = [select Id, Subject, HtmlValue from EmailTemplate where DeveloperName = 'SAP_Error_Message_Template_GB'];
                chatterGroupId = [SELECT Id FROM CollaborationGroup WHERE Name =: groupName].Id;
            } catch(Exception ex){
                System.debug('Error retrieving the Collaborative Group: ' + ex.getMessage());
            }
            
            for(OpportunityContactRole contactRole : contactRoles){
                String status = (String) responseMap.get(contactRole.Id).get('status');
                contactRole.SAPStatus__c = status;
                
                if(status == 'Success'){
                	contactRole.ErrorMessage__c = null;
                } else {
                    String errorMessage = (String) responseMap.get(contactRole.Id).get('errorMessage');
                    contactRole.ErrorMessage__c = errorMessage;
                    AutomatismsNotifications.generateNotifications(chatterGroupId, UserInfo.getUserId(), emailTemplate, contactRole, errorMessage, postToInsert, emailList, customNotifList);
                }
            }

            Database.update(contactRoles, false);
            AutomatismsNotifications.sendCustomNotifications(customNotifList);
            AutomatismsNotifications.insertFeedItems(postToInsert);
            
            if(!emailList.isEmpty()){
                Messaging.sendEmail(emailList, false);
            }
            
        }
        
    }
    
    public static Map<String, Object> sendRequest(Opportunity opp){
        SAPWS_Utility.opportunityWrapper = null;
        Map<String, Object> responseMap = new Map<String, Object>();
        Map<String, Object> oppFieldWrapper = new Map<String, Object>();
        
        oppFieldWrapper.put('Name', opp.Name);
        oppFieldWrapper.put('Id', opp.Id);
        oppFieldWrapper.put('IsClosed', false);
        oppFieldWrapper.put('AccountId', opp.AccountId);
        oppFieldWrapper.put('SalesOrg', opp.Sales_Org__c);
        oppFieldWrapper.put('Channel', opp.Dist_Channel__c);
        oppFieldWrapper.put('StageName', opp.StageName);
        oppFieldWrapper.put('IsGeneric__c', opp.IsGeneric__c);
        oppFieldWrapper.put('CloseDate', opp.CloseDate);
        oppFieldWrapper.put('SalesProgram', opp.SalesProgram__c);
        
        Map<String, Object> opportunityWrapper = new Map<String, Object>();
        opportunityWrapper.put('opportunity', oppFieldWrapper);
        opportunityWrapper.put('opportunityActorsList', opp.OpportunityContactRoles);
        opportunityWrapper.put('language', UserInfo.getLanguage());
        SAPWS_Utility.SapResponse response = OpportunityTransactionHandler.runSAPValidation(JSON.serialize(opportunityWrapper));
        responseMap.put('status', response.success ? 'Success' : 'Error');
        
        if(!response.success){
            String errorMessage = response.message + ':<p></p>';
            if(response.details != null){
                for( SAPWS_Utility.Detail detail : response.details ){
                    errorMessage += detail.message + ' (' + detail.code + ').<p></p>';
                }
            }
            
            responseMap.put('errorMessage', errorMessage);
        }
        
        return responseMap;
        
    }
    
}