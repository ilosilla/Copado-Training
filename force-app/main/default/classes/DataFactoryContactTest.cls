@isTest public with sharing class DataFactoryContactTest {

    @testSetup private static void testSetup() {
        TestUtils.EnableTriggers();        
    }

    @isTest private static void createContacts() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        Contact[] contacts = DataFactoryContact.createContacts(acc.Id, 10);
        Contact[] dbase = [select Id from Contact where AccountId = :acc.Id];
        System.assertEquals(10, dbase.size(), '10 contacts expected');
    }
}