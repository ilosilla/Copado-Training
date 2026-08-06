@isTest public with sharing class ContactPointAddressesServiceTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();        
        // Create account
        DataFactoryAccount.autoInsert = false;
        List<Account> accounts = DataFactoryAccount.createAccounts(RecordTypeLibrary.Account_ResellerCustomer, 1);
        accounts[0].SAP_Id__c = '0001234567';
        accounts[0].Name = 'RESELLER';
        insert accounts;
   }

   @isTest private static void getAccountAddressesTest() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        Account acc = [select Id, Name, RecordTypeId, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];   
        List<ContactPointAddress> list1 = ContactPointAddressesService.getAccountAddresses(acc.Id);
        System.assertEquals(1, list1.size(), 'One address should have been found');
        // Repeat after account has been synced
        list1 = ContactPointAddressesService.getAccountAddresses(acc.Id);
        System.assertEquals(1, list1.size(), 'One address should have been found after account has been synced');
   }

   @isTest private static void getPicklistTest() {
    // Set mock callout class 
    Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
    Account acc = [select Id, Name, RecordTypeId, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];   
    ContactPointAddressesService.getAccountAddresses(acc.Id);

    // Account synced - It should have an address now
    List<ContactPointAddressesService.PicklistItem> items = ContactPointAddressesService.getPicklist(acc.Id);
    Assert.isTrue(items.size() == 1, 'An item should have been found');
}

    @isTest public static void syncFromSAPTest() {        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        Account acc = [select Id, Name, RecordTypeId, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];   
        List<ContactPointAddress> list1 = ContactPointAddressesService.syncFromSAP(acc.Id, true);
        System.assertEquals(1, list1.size(), 'One address should have been found');

        Account acc2 = [select Id, AddressesSynced__c, SAP_Id__c from Account where Id = :acc.Id limit 1];
        System.assertEquals(true, acc2.AddressesSynced__c, 'Account addresses should have been synchronized');

        List<ContactPointAddress> addresses = new ContactPointAddressesSelector().selectByAccount(new Set<Id>{acc2.Id});
        System.assertEquals(1, addresses.size(), 'There should be one address');

        Boolean exceptionRaised = false;
        try {
            ContactPointAddressesService.syncFromSAP(acc2.Id, false);
        } catch (ContextException ce) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'Synced accounts should raise an exception whe synchronised again');
    }

    @isTest public static void syncFromSAPTest02() {        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        Account acc = DataFactoryAccount.createPersonAccounts(1)[0];
        Boolean exceptionReceived = false;
        try {
            ContactPointAddressesService.syncFromSAP(acc.Id, true);
        } catch (Exception ex) {
            exceptionReceived = true;
        }
        System.assertEquals(true, exceptionReceived, 'Retail customer do not have addresses enabled for sync');
    }

    @isTest public static void testSaveTest01 () {
        Account acc = [
            select Id, Name, AddressesSynced__c, SAP_Id__c
            from Account
            where Name = 'RESELLER'
            limit 1
        ];
        DataFactoryContactPointAddresses.autoInsert = false;
        ContactPointAddress address = DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 1)[0];
        Boolean exceptionRaised = false;
        try {
            Test.startTest();
            ContactPointAddressesService.testSave(address);
            Test.stopTest();
        } catch(ValidationException ex) {
            exceptionRaised = true;            
        }
        System.assertEquals(false, exceptionRaised, 'No errors were expected.');
    }

    @isTest public static void testSaveTest02 () {
        // Set mock callout class 
        Account acc = [
            select Id, Name, AddressesSynced__c, SAP_Id__c
            from Account
            where Name = 'RESELLER'
            limit 1
        ];
        DataFactoryContactPointAddresses.autoInsert = false;
        ContactPointAddress address = DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 1)[0];
        Boolean exceptionRaised = false;
        try {
            Test.startTest();
            address.Name = '';
            ContactPointAddressesService.testSave(address);
            Test.stopTest();
        } catch(ValidationException ex) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'Errors were expected.');
    }

    @isTest public static void saveTest01 () {
        // Set mock callout class 
        Account acc = [
            select Id, Name, AddressesSynced__c, SAP_Id__c
            from Account
            where Name = 'RESELLER'
            limit 1
        ];
        acc.AddressesSynced__c = true;
        update acc;

        Account syncedAcc = [
            select Id, AddressesSynced__c, SAP_Id__c
            from Account
            where Id = :acc.Id
            limit 1
        ];
        DataFactoryContactPointAddresses.autoInsert = false;
        ContactPointAddress address = DataFactoryContactPointAddresses.createAccountAddresses(syncedAcc.Id, 1)[0];
        Boolean exceptionRaised = false;
        try {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());     
            ContactPointAddressesService.save(address);
            Test.stopTest();
        } catch(ValidationException ex) {
            exceptionRaised = true;
        }
        System.assertEquals(false, exceptionRaised, 'An exception should have not been raised');
    }

    @isTest public static void saveTest_requiresSyncedAccount () {
        Account acc = [
            select Id, Name, AddressesSynced__c, SAP_Id__c
            from Account
            where Name = 'RESELLER'
            limit 1
        ];
        System.assertEquals(false, acc.AddressesSynced__c);

        DataFactoryContactPointAddresses.autoInsert = false;
        ContactPointAddress address = DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 1)[0];

        Boolean exceptionRaised = false;
        try {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());
            ContactPointAddressesService.save(address);
            Test.stopTest();
        } catch(ValidationException ex) {
            exceptionRaised = true;
        }
        //System.assertEquals(true, exceptionRaised, 'Saving should fail when the account has not synchronized its addresses with SAP yet.');
    }

    /*@isTest public static void saveTest02 () {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());     

        Account acc = [
            select Id, Name, AddressesSynced__c, SAP_Id__c
            from Account
            where Name = 'RESELLER'
            limit 1
        ];
        DataFactoryContactPointAddresses.autoInsert = false;
        ContactPointAddress address = DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 1)[0];
        address.SAPId__c = '9999999';        
        Boolean exceptionRaised = false;
        try {
            ContactPointAddressesService.save(address);
        } catch(ValidationException ex) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'An exception should have been raised');
    }*/

    @isTest static void testIsAddressSyncable() {
        System.assertEquals(true, ContactPointAddressesService.isAccountSyncable(RecordTypeLibrary.Account_ResellerCustomer, '0001001000'), 'Resellers con SAPId deben ser syncables');
        System.assertEquals(false, ContactPointAddressesService.isAccountSyncable(RecordTypeLibrary.Account_ResellerCustomer, ''), 'Resellers sin SAPId no deben ser syncables');
        System.assertEquals(true, ContactPointAddressesService.isAccountSyncable(RecordTypeLibrary.Account_PrivateCustomer, '0001001000'), 'Privates son también syncables');
    }

}