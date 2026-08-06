@isTest public with sharing class ContactPointAddressesSelectorTest {

    @testSetup private static void testSetup() {
        DataFactoryContactPointAddresses.createRecords(2, 5);        
    }

    @isTest public static void testSelectById() {
        ContactPointAddressesSelector selector = new ContactPointAddressesSelector();
        ContactPointAddress[] cpas = [select Id from ContactPointAddress limit 4];
        Set<Id> ids = TypeConversionCommons.listToSet(cpas);
        ContactPointAddress[] records = selector.selectById(ids);
        System.assertEquals(cpas.size(), records.size(), 'Wrong number of records');
    }

    @isTest public static void testSelectByAccount() {
        ContactPointAddressesSelector selector = new ContactPointAddressesSelector();
        Account[] accs = [select Id from Account];
        ContactPointAddress[] records = selector.selectByAccount(new Set<Id>{accs[0].Id});    
        System.assertEquals(5, records.size(), 'There should be 5 records');
    }
}