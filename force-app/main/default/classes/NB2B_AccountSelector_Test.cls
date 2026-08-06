@isTest public class NB2B_AccountSelector_Test {
	@TestSetup
    static public void setupData(){
        Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        acc.SAP_Id__c = 'test';
        insert acc;
        WebStore webStore = new WebStore(Name='United Kingdom');
        insert webStore;
        
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=acc.Id, CurrencyIsoCode='EUR');
        insert cart;
        NB2B_SetupClassTest.setupContactPointAddressTestData();
        ContactPointAddress address = [Select id from ContactPointAddress limit 1]; 
        address.NB2B_thirdpartyAddress__c = true;
        update address;
        
    }
    @isTest public static void getUserRoles() {
        System.assertEquals(0, NB2B_AccountSelector.getUserRoles([Select id from Account limit 1].Id).size());
       
    }
    @isTest public static void getAccountForUserRoles() {
        System.assertEquals(1, NB2B_AccountSelector.getAccountForUserRoles([Select id from WebCart limit 1].Id).size());
       
    }
    @isTest public static void getAccountShippingAddress() {
        System.assertEquals(null, NB2B_AccountSelector.getAccountShippingAddress([Select id from Account limit 1].Id));
       
    }
    @isTest public static void selectContactBySapId() {
        List<String> strlist = new List<String>();
        strlist.add('test');
        System.assertEquals(1, NB2B_AccountSelector.selectContactBySapId(strlist).size());
       
    }
    @isTest public static void getSalesChannel() {
        System.assertEquals(0, NB2B_AccountSelector.getSalesChannel().size());
       
    }
    @isTest public static void getNumDays() {
        System.assertEquals(3, NB2B_AccountSelector.getNumDays('NB2B_PriceSyncJob'));
       
    }
    @isTest public static void selectPointAddressesByAccountId() {
        System.assertEquals(0, NB2B_AccountSelector.selectPointAddressesByAccountId([Select id from Account limit 1].Id).size());
       
    }

}