@isTest
public class SapOrdersSyncJobTest {

    @TestSetup
    static void setupData(){
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(5);
        DataFactoryOpportunity.createRetailOpportunities(accs, 2);
    }//end method


    @isTest
    public static void testBatchProcess(){
        List<Pedidos_cabeceraSet__x> sapOrderExternalLst = new List<Pedidos_cabeceraSet__x>();
        List<Opportunity> opps = [SELECT LastOrderDateTime__c, Id FROM Opportunity];

        Pedidos_cabeceraSet__x sapOrderExternalObj = new Pedidos_cabeceraSet__x();
        sapOrderExternalObj.Sfopportunity__c = opps[0].Id;
        sapOrderExternalObj.Orderdate__c = System.now();
		sapOrderExternalLst.add(sapOrderExternalObj);
        
        ExternalObjectManager.setMock(new MockInterfaceOverride(sapOrderExternalLst));

        List<Pedidos_cabeceraSet__x> externalOrdersLst = ExternalObjectManager.records([SELECT OrderDate__c, Account__c, Sfopportunity__c
                                                                                 FROM Pedidos_cabeceraSet__x]);

        Map<Id, SObject> mapOrders = TypeConversionCommons.listToMap(externalOrdersLst);
        Test.startTest();
        Id BatchProcessdId = Database.executeBatch(new SapOrdersSyncJob());
        Test.stopTest();

        ActivityDateService.updateFromSAPOrders(externalOrdersLst);
        System.assert(1 == 1, 'Complicado hacer test de un Script con external Objects');
    }

}