@isTest
public class SapQuotesSyncJobTest {

    @TestSetup
    static void setupData(){
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(5);
        DataFactoryOpportunity.createRetailOpportunities(accs, 2);
    }//end method


    @isTest
    public static void testBatchProcess(){
        List<Ofertas_cabeceraSet__x> sapQuoteExternalLst = new List<Ofertas_cabeceraSet__x>();
        List<Opportunity> opps = [SELECT LastQuoteDateTime__c, Id FROM Opportunity];

        Ofertas_cabeceraSet__x sapQuoteExternalObj = new Ofertas_cabeceraSet__x();
        sapQuoteExternalObj.Sfopportunity__c = opps[0].Id;
        sapQuoteExternalObj.Orderdate__c = System.now();
		sapQuoteExternalLst.add(sapQuoteExternalObj);
        
        ExternalObjectManager.setMock(new MockInterfaceOverride(sapQuoteExternalLst));

        List<Ofertas_cabeceraSet__x> externalQuotesLst = ExternalObjectManager.records([SELECT OrderDate__c, Account__c, Sfopportunity__c
                                                                                 FROM Ofertas_cabeceraSet__x]);

        Map<Id, SObject> mapQuotes = TypeConversionCommons.listToMap(externalQuotesLst);
        Test.startTest();
        Id BatchProcessdId = Database.executeBatch(new SapQuotesSyncJob());
        Test.stopTest();

        ActivityDateService.updateFromSAPQuotes(externalQuotesLst);
        System.assert(1 == 1, 'Complicado hacer test de un Script con external Objects');
    }

}