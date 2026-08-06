public with sharing class B2B_SapAccountingInfoController {

    @AuraEnabled (cacheable=true)
    public static List<Sales_Relationship__c> getUserRoles(String recordIdStr){
        if(
            Sales_Relationship__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Sales_Relationship__c.fields.Account_org__c.isAccessible()
        ){    
            List<WebCart> webCartAccount = NB2B_AccountSelector.getAccountForUserRoles(recordIdStr);
            String accountId = webCartAccount[0].AccountId;
            return NB2B_AccountSelector.getUserRoles(accountId);
        }else{
            Logger.error('You have no visibility to the object Sales_Relationship__c');
            Logger.saveLog();
            return null;
        }
    }
}