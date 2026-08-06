@isTest public class DataFactoryOppCustomProjectsTest {

    @testSetup static void testSetup() {
        TestUtils.enableTriggers();
        SystemSettings.CPDeletionTime = 0;
    }

    @isTest static void testCreateRecords() {
        List<OppCustomProject__c> projects = DataFactoryOppCustomProjects.createRecords(3);
        List<OppCustomProject__c> dbProjects = [select Id from OppCustomProject__c];
        System.assertEquals(projects.size(), dbProjects.size(), 'The two lists should have the same size');
    }
}