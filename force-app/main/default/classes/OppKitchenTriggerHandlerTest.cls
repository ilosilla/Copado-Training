@isTest private class OppKitchenTriggerHandlerTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        SystemSettings.CPNotificationsEnabled = true;
        SystemSettings.CPDeletionTime = 2;
        DataFactoryOppKitchen.createRecords();
    } // testSetup   

    @isTest private static void testInsert() {
        OppKitchen__c[] records = [select Id from OppKitchen__c];
        System.assertEquals(1, records.size(), 'A kitchen');
        Opportunity[] opps = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp : opps) {
            System.assertEquals(OpportunitiesInfoCommons.KITCHEN_TYPE, opp.InfoType__c, 'The opportunity should be set as a ' + OpportunitiesInfoCommons.KITCHEN_TYPE);
        }
    }

    @isTest private static void testDelete() {
        OppKitchen__c[] records = [select Id from OppKitchen__c];
        delete records;
        Opportunity[] opps = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp : opps) {
            System.assertEquals(true, String.IsBlank(opp.InfoType__c), 'InfoType__c should have been cleared');
        }
    }


}