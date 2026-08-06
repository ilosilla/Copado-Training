@isTest public class DataFactoryOppKitchenTest {

    @testSetup static void testSetup() {
        TestUtils.enableTriggers();
        SystemSettings.CPNotificationsEnabled = true;
        SystemSettings.CPDeletionTime = 2;
        DataFactoryOppKitchen.createRecords();
    }

    @isTest static void testCreate() {
        OppKitchen__c[] ks = [select Id from OppKitchen__c];
        System.assertNotEquals(0, ks.size(), 'There should be at least a kitchen');
    }
}