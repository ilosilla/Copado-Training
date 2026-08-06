@isTest
public with sharing class MoodboardsSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 3);
        Moodboard__c aux = new Moodboard__c(Opportunity__c = opps[0].id, Name = 'Test Moodboard');
        insert aux;
    }

    @isTest
    private static void selectById() {
        Set<Id> moodboardsIds = new Set<id>();
        for(Moodboard__c l : [Select Id from Moodboard__c]) {
            moodboardsIds.add(l.id);
        }

        List<Moodboard__c> result = new MoodboardsSelector().selectById(moodboardsIds);
        System.assertEquals(1, result.size(), '1 Moodboard expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Moodboard__c moodboard = [Select Id from Moodboard__c LIMIT 1];
        Moodboard__c result = new MoodboardsSelector().selectById(moodboard.Id);
        System.assert(result != null, 'No se ha encontrado el Moodboard');
    }
}