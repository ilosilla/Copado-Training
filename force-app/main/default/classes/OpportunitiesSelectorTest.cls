@isTest
public with sharing class OpportunitiesSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> listAcc = DataFactoryAccount.createAccounts(10);
        DataFactoryOpportunity.createTradeOpportunities(listAcc, 1);
    }

    @isTest
    private static void selectById() {
        Set<Id> oppsIds = new Set<id>();
        for(Opportunity opp : [Select Id from Opportunity]) {
            oppsIds.add(opp.id);
        }
        OpportunitiesSelector selector = new OpportunitiesSelector();
        List<Opportunity> result = selector.selectById(oppsIds);
        System.assertEquals(10, result.size(), '10 opportunities expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Opportunity opp = [Select Id from Opportunity LIMIT 1];
        Opportunity result = new OpportunitiesSelector().selectById(opp.Id);
        System.assert(result != null, 'No se ha encontrado el Opportunity');
    }

}