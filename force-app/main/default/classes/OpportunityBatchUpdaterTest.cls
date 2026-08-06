@isTest public with sharing class OpportunityBatchUpdaterTest {

    @TestSetup static void makeData(){
                
        TestUtils.enableTriggers();
        SystemSettings.CPDeletionTime = 0;

        OpportunityCommons.getClosedWonStages();
        OpportunityCommons.getClosedLostStages();

        DataFactoryOppCustomProjects.createRecords(2);
        DataFactoryOppKitchen.createRecords();
        DataFactoryOppFacade.createFacade();
        DataFactoryOpportunity.createRetailOpportunities(1, 2);

        List<Opportunity> opps = [select Id, StageName, InfoType__c from Opportunity];
        for (Opportunity opp : opps) {
            opp.InfoType__c = '';
        }        
        update opps;
    }

    @isTest static void test1() {
        Opportunity[] opps = [select Id, InfoType__c from Opportunity];
        System.assertEquals(6, opps.size(), 'There should be 6 opportunities');
        for (Opportunity opp : opps) {
            System.assertEquals(null, opp.InfoType__c, 'All infotypes should have been cleared');
        }

        Test.startTest();
        OpportunityBatchUpdater updaterCP = new OpportunityBatchUpdater('PROJECT'); 
        Database.executeBatch(updaterCP);

        OpportunityBatchUpdater updaterKI = new OpportunityBatchUpdater('KITCHEN'); 
        Database.executeBatch(updaterKI);

        OpportunityBatchUpdater updaterFA = new OpportunityBatchUpdater('FACADE'); 
        Database.executeBatch(updaterFA);        
        Test.stopTest();

        Integer projects = 0;
        Integer kitchens = 0;
        Integer facades = 0;

        Opportunity[] opps2 = [select Id, InfoType__c from Opportunity];
        for (Opportunity opp2 : opps2) {
            if (opp2.InfoType__c == 'PROJECT') {
                projects++;
            }
            if (opp2.InfoType__c == 'KITCHEN') {
                kitchens++;
            }
            if (opp2.InfoType__c == 'FACADE') {
                facades++;
            }
        }
        System.assertEquals(2, projects, 'There should be 2 projects');
        System.assertEquals(1, kitchens, 'There should be 1 kitchen');
        System.assertEquals(1, facades, 'There should be 1 facade');

    }
}