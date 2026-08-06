@isTest public class OppFacadeTriggerHandlerTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        SystemSettings.CPNotificationsEnabled = true;
        SystemSettings.CPDeletionTime = 2;
        DataFactoryOppFacade.createFacade();
    } // testSetup

    @isTest private static void testInsert() {
        OppFacade__c[] facades = [select Id from OppFacade__c];
        System.assertEquals(1, facades.size(), 'A facade');
        Opportunity[] opps = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp : opps) {
            System.assertEquals(OpportunitiesInfoCommons.FACADE_TYPE, opp.InfoType__c, 'The opportunity should be set as a ' + OpportunitiesInfoCommons.FACADE_TYPE);
        }
    }

    @isTest private static void testDelete() {
        OppFacade__c[] facades = [select Id from OppFacade__c];
        delete facades;
        Opportunity[] opps = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp : opps) {
            System.assertEquals(true, String.IsBlank(opp.InfoType__c), 'InfoType__c should have been cleared');
        }
    }
    
}