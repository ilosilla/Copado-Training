/**
* @author 		Ramón Prades
* @date 		November 2021
* @group 		Utils
* @description 	test Class SAPAddressHelper
*/
@isTest public class SAPAddressHelperTest {

@TestSetup static void makeData(){
    TestUtils.enableTriggers();        
    // Create account
    DataFactoryAccount.autoInsert = false;
    List<Account> accounts = DataFactoryAccount.createAccounts(1);
    accounts[0].SAP_Id__c = '0001234567';
    insert accounts;
}

@isTest static void sendAddressToSAPTest() {
    // Set mock callout class 
    Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        

    Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account limit 1];
    ContactPointAddress address = new ContactPointAddress();
    address.addressType = 'Shipping';
    address.Name = 'Test adddress';
    //address.SAPId__c = acc.SAP_Id__c;
    address.ParentId = acc.Id;
    address.City = 'Ilkley';
    address.CountryCode = 'GB';
    address.PostalCode = 'LS9 9EE';
    address.stateCode = 'YO';
    address.Street = '9 The Grove';
    address.EMail__c = 'aaa@ccc.cxm';
    address.Phone__c = '111 222 333';  
    address.Mobile__c = '666 777 888';
    Boolean exceptionRaised = false;
    SAPAddressHelper.sendAddressToSAP(address);
    System.assertEquals(false, exceptionRaised, 'No exception expected');

    try {
        address.Name = '';
        SAPAddressHelper.sendAddressToSAP(address);
    } catch (Exception ae) {
        exceptionRaised = true;
    }
    System.assertEquals(true, exceptionRaised, 'Exception expected');
}

    @isTest public static void readAccountAddressesTest() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        List<ContactPointAddress> list1 = SAPAddressHelper.readAccountAddresses('0001234567', true);        
        System.assertEquals(1, list1.size(), 'One address should have been found');

        Boolean exceptionRaised = false;
        try {
            List<ContactPointAddress> list2 = SAPAddressHelper.readAccountAddresses('0009999999', true);        
        } catch (Exception ex) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'Exception expected');
    }

    @isTest public static void readInvoiceAddressesTest() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        List<ContactPointAddress> list1 = SAPAddressHelper.readInvoiceAddresses('0001234567', true);        
        System.assertEquals(1, list1.size(), 'One address should have been found');

        Boolean exceptionRaised = false;
        try {
            List<ContactPointAddress> list2 = SAPAddressHelper.readInvoiceAddresses('0009999999');        
        } catch (Exception ex) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'Exception expected');
    }

    @isTest public static void readInvoiceAddressesTest2() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        ContactPointAddress cpa = SAPAddressHelper.readInvoiceDeliveryAddress('0001234567');        
        System.assertNotEquals(null, cpa, 'Delivery address should have been found');
    }

} // class