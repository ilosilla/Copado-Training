@isTest public class OpportunityCommonsTest {

    @isTest static void getClosedLostStages() {
        List<String> stages = OpportunityCommons.getClosedLostStages();
        System.assertNotEquals(0, stages.size(), 'There should be at least a Closed Lost stage');
    }

    @isTest static void getClosedWonStages() {
        List<String> stages = OpportunityCommons.getClosedWonStages();
        System.assertNotEquals(0, stages.size(), 'There should be at least a Closed Won stage');
    }

    

}