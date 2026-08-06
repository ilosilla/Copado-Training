/*-----------------------------------------------------------------------------------------
     Apex Class:        B2B_SapAccountingInfoControllerTest
     Created Date:      14/03/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Test to LWC controller
------------------------------------------------------------------------------------------*/
@isTest
public with sharing class B2B_SapAccountingInfoControllerTest {

    @TestSetup
    static void setupData(){
    	CommerceEntitlementPolicy policy = new CommerceEntitlementPolicy(
        	Name = 'SPAIN'
        );
        insert policy;
    
        WebStore webStore = new WebStore(Name='Spain');
        insert webStore;

		Product2 prod = new Product2(
        	Name = 'test',
            productCode = '1235',
            StockKeepingUnit = '12345'
        );
        insert prod;
        
        Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        acc.SAP_Id__c = '1234';
        insert acc;
    
    	WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=acc.Id,PoNumber='test');
        insert cart;
    
        Trigger_configuration__c triggerConf = new Trigger_configuration__c(Name = 'Porcelanosa', CurrencyIsoCode = 'EUR', Sales_Relationship__c = true);
        insert triggerConf;
        
    	Sales_Relationship__c salesRel = new Sales_Relationship__c( Name = 'Test sales' , Account_org__c = acc.Id, Distribution_Channel__c = '10' , Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE);
    	insert salesRel;
        

    }
    
    @isTest
    public static void NB2B_selectSalesRelJob_Test() {
        List<WebCart> listWC  = [SELECT Id from WebCart];
        WebCart wc = listWC[0];
        Test.startTest();
        List<Sales_Relationship__c> listsales= B2B_SapAccountingInfoController.getUserRoles(wc.Id);
        System.assertEquals(listsales.isEmpty(), false);
        Test.stopTest();
    }
    
}