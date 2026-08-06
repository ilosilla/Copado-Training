/**
* @author 		Ramón Prades
* @date 		January 2022
* @group 		Test
* @description 	Test for ContactAddressController
*/
@isTest public class ContactAddressControllerTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();        
        // Create account
        DataFactoryAccount.autoInsert = false;
        List<Account> accounts = DataFactoryAccount.createAccounts(2);
        accounts[0].SAP_Id__c = '0001234567';
        accounts[0].Name = 'RESELLER';
        accounts[0].RecordTypeId = RecordTypeLibrary.Account_ResellerCustomer;

        accounts[1].SAP_Id__c = '0001234568';
        accounts[1].Name = 'TRADE';

        insert accounts;
    }

    @isTest public static void syncAccountAddressesTest() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        

        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];
        ContactAddressController.DataDTO dto = ContactAddressController.syncSAPAddresses(acc.Id);
        System.assertEquals(true, dto.synced, 'Address should be synchronized');

        Account acc2 = [select Id, AddressesSynced__c, SAP_Id__c from Account where Id = :acc.Id limit 1];
        dto = ContactAddressController.syncSAPAddresses(acc2.Id);
        System.assertEquals(true, dto.alreadySynced, 'Address should have been already synced!');        
    }

    @isTest public static void syncAccountAddressesTest2() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        

        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account where Name = 'TRADE' limit 1];
        acc.SAP_Id__c = '';
        update acc;
        ContactAddressController.DataDTO dto = ContactAddressController.syncSAPAddresses(acc.Id);
        System.assertEquals(false, dto.synced, 'Address should not be synchronized');
        System.assertEquals(false, dto.syncable, 'Address should not be syncable');
    }

    @isTest public static void testAddressUpsert () {
        // Set mock callout class 
        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];
        ContactPointAddress address = getContactAddress(acc);
        Boolean exceptionRaised = false;
        try {
            ContactAddressController.testAddressUpsert(address);
        } catch (Exception ex) {
            exceptionRaised = true;
        }
        System.assertEquals(false, exceptionRaised, 'A exception should not have been received');
    }

    @isTest public static void testAddressUpsert_2 () {
        // Set mock callout class 
        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];
        ContactPointAddress address = getContactAddress(acc);
        address.Name = '';
        Boolean exceptionRaised = false;
        try {
            ContactAddressController.testAddressUpsert(address);
        } catch (Exception ex) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'A exception should not have received');
    }

    @isTest public static void saveAddressTest () {
        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];
        acc.AddressesSynced__c = true;
        update acc;
        DataFactoryContactPointAddresses.autoInsert = false;
        ContactPointAddress address = DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 1)[0];
        address.SAPId__c = null;
        // Set mock callout class 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        ContactPointAddress received;
        try {
            received = ContactAddressController.saveAddress(address);
        } catch (Exception ex) {
            System.assert(false, ex.getMessage());
        }
        Test.stopTest();
        System.assertNotEquals(null, received, 'No address has been received');
        Boolean exceptionRaised = false;
        try {
            address.Name = '';
            received = ContactAddressController.saveAddress(address);
        } catch (Exception ex) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'A exception should have been received');
    }

    private static ContactPointAddress getContactAddress(Account acc) {
        ContactPointAddress address = new ContactPointAddress();
        address.addressType = 'Billing';
        address.Name = 'Test adddress';
        address.SAPId__c = acc.SAP_Id__c;
        address.ParentId = acc.Id;
        address.City = 'Ilkley';
        address.CountryCode = 'GB';
        address.PostalCode = 'LS9 9EE';
        //address.stateCode = 'YO';
        address.Street = '9 The Grove';
        address.EMail__c = 'aaa@ccc.cxm';
        address.Phone__c = '111 222 333';  
        address.Mobile__c = '666 777 888';
        return address;
    }


} // class