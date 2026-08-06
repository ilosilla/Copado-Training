@isTest public with sharing class LeadsSelectorTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactorylead.createUSWebRequest(5);
    }

    @isTest private static void selectById() {
        Set<Id> leadIds = new Set<id>();
        for(lead l : [Select Id from Lead]) {
            leadIds.add(l.id);
        }
        LeadsSelector selector = new LeadsSelector();
        List<Lead> result = selector.selectById(leadIds);
        System.assertEquals(5, result.size(), '5 leads expected!');
    }

}