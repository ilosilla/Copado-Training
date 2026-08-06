/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_AreaCalculationController
     Created Date:      22/04/2022
     Author:            Ignacio Galindo Schuhmacher
     Mail:              ignacio.galindo@nubika.com
     Description:       Class to select Sales Organization
------------------------------------------------------------------------------------------*/
public without sharing class  NB2B_SalesOrgSelectorController {
	@AuraEnabled
    public static List<Sales_Relationship__c> getSalesOrgList(){
        User user;
        Id AccountId;
        List<Sales_Relationship__c> salesList;
       	try{
            user = [Select id, ContactId, Contact.AccountId, Contact.Account.Name,Contact.Account.Country_formula__c, 
                            Contact.Account.CurrencyIsoCode from User where id=:UserInfo.getUserId() limit 1];
            salesList = [Select id, Sales_Org__c, Name, Distribution_Channel__c, Sales_Office__c 
                         from Sales_Relationship__c where Account_Org__c =: user.Contact.AccountId and B2BEnabled__c = true];
            
        }catch(Exception e){
        	System.debug('Exception e:' + e);
        }
        return salesList;
    }
    
    @AuraEnabled
    public static void saveContactSalesOrg(String salesOrgId) {
        
        User user;
        user = [Select id, ContactId, Contact.AccountId, Contact.Account.Name,Contact.Account.Country_formula__c, 
                            Contact.Account.CurrencyIsoCode from User where id=:UserInfo.getUserId() limit 1];
        Contact contactUser = [SELECT SAP_Accounting_Info__c FROM Contact WHERE Id = :user.ContactId LIMIT 1];
        contactUser.SAP_Accounting_Info__c = salesOrgId;
        update contactUser;
    }

}