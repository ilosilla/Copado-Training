public without sharing class NB2B_AccountSelector {
    
    //Get User Roles from object Sales_Relationship__c
    public static List<Sales_Relationship__c> getUserRoles(String recordIdStr){
        return [
            SELECT Id, Name, Account_org__c 
            FROM Sales_Relationship__c 
            WHERE Account_org__c =:recordIdStr
        ];
    }

    //Get User Roles from object Sales_Relationship__c
    public static List<WebCart> getAccountForUserRoles(String webCartId){
        return [
            SELECT  AccountId
            FROM WebCart  
            WHERE Id =:webCartId
        ];
    }
    //Get User Roles from object Sales_Relationship__c
    public static Address getAccountShippingAddress(String accountId){
        System.debug('NB2B_AccountSelector getAccountShippingAddress');
        return [
            SELECT  BillingAddress
            FROM Account  
            WHERE Id =:accountId limit 1
        ].BillingAddress;
    }

    public static List<Contact> selectContactBySapId(List<String> listSapsId){
        return [
            SELECT Id, Account.SAP_Id__c  
            FROM Contact 
            WHERE Account.SAP_Id__c IN : listSapsId
        ];
    }

    public static List<SalesChannel> getSalesChannel(){
        return [
            SELECT Id, ExternalChannelNumber 
            FROM SalesChannel
        ];
    }

    public static Integer getNumDays(String labelName){
        List<NB2B_ExternalObjLoadDays__mdt> mdt =[
            SELECT NB2B_NumDays__c, Label  
            FROM NB2B_ExternalObjLoadDays__mdt 
            WHERE Label =: labelName
        ];
        return Integer.valueOf(mdt[0].NB2B_NumDays__c);
    }

    public static List<ContactPointAddress> selectPointAddressesByAccountId(Id accountId){
        return [
            SELECT Id, Name, IsPrimary, IsDefault, Address, SAPId__c, ParentId, NB2B_thirdpartyAddress__c
            FROM ContactPointAddress
            WHERE ParentId = : accountId
            AND SAPId__c != null
            //AND AddressType = 'Shipping'
            //AND UsageType NOT IN('Inactive', 'Temporary')
        ];
    }

    public static List<PorcelanosaAddress__c> selectPointAddressesByDeliveryGroup(String deliveryGroup){
        return [
            SELECT Id, Name, NBK_Address__c, NBK_Address_Type__c
            FROM PorcelanosaAddress__c
            WHERE NBK_isActive__c = TRUE
            AND NBK_Address_Type__c includes ('Collection Point')
            AND NBK_Sales_Org__r.SalesOrg__c = : deliveryGroup
        ];
    }

}