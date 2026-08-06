@isTest public with sharing class ObjectDeleterJobTest {

    private static final Integer NUM_RECORDS = 50;

    @testSetup private static void testSetup() {
        DataFactoryAccount.createAccounts(NUM_RECORDS);
    }

    @isTest private static void testTestMode() {
        ObjectDeleterJob deleter = new ObjectDeleterJob('Account');
        deleter.setCondition('BillingCity = \'London\'');
        deleter.setTest(true);
        Test.startTest();
            Database.executeBatch(deleter);
        Test.stopTest();
        Account[] accounts = [select Id from Account];
        Assert.isTrue(accounts.size() == NUM_RECORDS, 'No record should have been deleted');
    }

    @isTest private static void testNoTestMode() {
        ObjectDeleterJob deleter = new ObjectDeleterJob('Account');
        deleter.setCondition('BillingCity = \'London\'');
        deleter.setTest(false);
        Test.startTest();
            Database.executeBatch(deleter);
        Test.stopTest();
        Account[] accounts = [select Id from Account];
        Assert.isTrue(accounts.size() == 0, 'All records ahould have been deleted');
    }

    @isTest private static void testConditionRequired() {
        ObjectDeleterJob deleter = new ObjectDeleterJob('Account');
        deleter.setTest(false);
        Test.startTest();
            Database.executeBatch(deleter);       
        Test.stopTest();
        Account[] accounts = [select Id from Account];
        Assert.isTrue(accounts.size() == NUM_RECORDS, 'No record should have been deleted');
    }


}