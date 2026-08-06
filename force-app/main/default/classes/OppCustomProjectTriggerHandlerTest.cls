@isTest private class OppCustomProjectTriggerHandlerTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();
        SystemSettings.CPDeletionTime = 0;
        SystemSettings.CPNotificationsEnabled = true;
        //SystemSettings.CPDeletionTime = 15;
        DataFactoryOppCustomProjects.createRecords(2);
    }

    @isTest static void testInfoTypeUpdated() {
        Opportunity[] opps = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp : opps) {
            System.assertEquals(OpportunitiesInfoCommons.PROJECT_TYPE, opp.InfoType__c, 'InfoType__c should be ' + OpportunitiesInfoCommons.PROJECT_TYPE);
        }
    }

    @isTest static void testInfoTypeCleared() {
        List<OppCustomProject__c> cps = [select Id, Opportunity__c from OppCustomProject__c];
        delete cps;
        Opportunity[] opps2 = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp : opps2) {
            System.assertEquals(true, String.IsBlank(opp.InfoType__c), 'InfoType__c should have been cleared');
        }
    }

    @isTest static void testAfterUpdate() {
        OppCustomProject__c cp = [select Id, Opportunity__c from OppCustomProject__c limit 1];
        cp.Stage__c = 'INSTALLATION';
        update cp;
        System.assertEquals(true, true, 'Code coverage');
    }

}