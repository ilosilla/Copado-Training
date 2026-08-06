@isTest class ContactPointAddressTriggerHandlerTest {

    @TestSetup static void makeData() {
        TestUtils.enableTriggers();        
        // Create account
        List<Account> accounts = DataFactoryAccount.createAccounts(1);
    }

    @isTest static void testDelete1() {
        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account limit 1];
        ContactPointAddress address = getContactAddress(acc);
        Boolean exceptionRaised = false;
        try {
            insert address;
            delete address;
        } catch (Exception x) {
            exceptionRaised = true;
        }
        System.assertEquals(false, exceptionRaised, 'No exception should have been raised');
    }

    @isTest static void testDelete2() {
        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account limit 1];
        ContactPointAddress address = getContactAddress(acc);
        Boolean exceptionRaised = false;
        try {
            address.SAPId__c = '0001234567';
            insert address;
            delete address;
        } catch (Exception x) {
            exceptionRaised = true;
        }
        System.assertEquals(true, exceptionRaised, 'A exception should have been raised');
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

}