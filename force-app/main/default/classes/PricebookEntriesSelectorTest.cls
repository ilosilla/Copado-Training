@isTest
public with sharing class PricebookEntriesSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryProduct.createProducts();
    }

    @isTest
    private static void selectById() {
        Set<Id> pbEntriesIds = new Set<id>();
        for(PricebookEntry l : [Select Id from PricebookEntry]) {
            pbEntriesIds.add(l.id);
        }
        Test.startTest();
        List<PricebookEntry> result = new PricebookEntriesSelector().selectById(pbEntriesIds);
        Test.stopTest();
        System.assert(result.size() > 0, 'No se ha encontrado pricebook entry');
    }

    @isTest
    private static void selectByTariffAndProduct() {
        Set<String> tariffs = new Set<String>{'G77763', 'Y66RWT'};
        Set<String> products = new Set<String>{'1887755', '100000555'};
        Test.startTest();
        List<PricebookEntry> result = new PricebookEntriesSelector().selectByTariffAndProduct(tariffs, products);
        Test.stopTest();
        System.assert(result.size() == 0, 'Se ha encontrado pricebook entry');
    }

    @isTest private static void selectByPricebook() {
        PricebookEntry entry = [Select Id, Product2Id, Pricebook2Id, CurrencyIsoCode from PricebookEntry limit 1];
        Test.startTest();
        List<PricebookEntry> result = new PricebookEntriesSelector().selectByPricebook(entry.Pricebook2Id, entry.CurrencyIsoCode, new Set<Id>{entry.Product2Id});
        Test.stopTest();
        Assert.areEqual(1, result.size(), 'There should be 1 entry'); 
    }

}