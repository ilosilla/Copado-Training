@isTest public with sharing class DataFactoryContactPointAddressesTest {

    @isTest public static void testCreate() {
        DataFactoryContactPointAddresses.createRecords(2, 5);
        ContactPointAddress[] records = [select Id, SAPId__c from ContactPointAddress];
        System.assertEquals(10, records.size(), 'There should be 10 records');
    }

    @isTest public static void testCreate2() {
        DataFactoryContactPointAddresses.createRecords(2, 5);
        Account acc = [select Id from Account limit 1];
        ContactPointAddress[] before = [select Id, SAPId__c from ContactPointAddress where parentId = :acc.Id];
        DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 2);
        ContactPointAddress[] after = [select Id, SAPId__c from ContactPointAddress where parentId = :acc.Id];
        System.assertEquals(before.size() + 2, after.size(), 'There should be 2 more records');
    }

    @isTest public static void testUSRecords() {
        DataFactoryContactPointAddresses.createUSRecords(10);
        ContactPointAddress[] after = [select Id, SAPId__c from ContactPointAddress];
        System.assertEquals(10, after.size(), 'There should be 10 records');
    }
}