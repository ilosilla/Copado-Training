public without sharing class AccountSapErrorsController {
	@AuraEnabled
    public static List<Sales_Relationship__c> returnAccErrors(String recordId){
        List<Sales_Relationship__c> returnList = [SELECT Id, Name, CreatedDate, Reason_of_Creation__c, Sap_Status__c, Error_Message__c
                                                 FROM Sales_Relationship__c 
                                                  WHERE Account_Org__c =: recordId AND Sap_Status__c != 'Success'];
        
        return returnList;
    }
    
    @AuraEnabled
    public static String retry(String recordId){
        String result = '';
        
        try{
            Automatic_AccountSendToSAP.SendToSAP(new List<Id>{Id.valueOf(recordId)});
        } catch(Exception ex){
            result = ex.getMessage();
        }
        
        return result;
    }
}