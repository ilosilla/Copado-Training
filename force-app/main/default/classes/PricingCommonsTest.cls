@isTest public with sharing class PricingCommonsTest {
    
    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();
    }

    @isTest private static void getPricebookEntries() {
        PricebookEntry entry = [Select Id, Product2Id, Pricebook2Id, CurrencyIsoCode from PricebookEntry limit 1];
        Test.startTest();
        Map<Id, PricebookEntry> result = PricingCommons.getPricebookEntries(entry.Pricebook2Id, entry.CurrencyIsoCode, new Set<Id>{entry.Product2Id});
        Test.stopTest();
        Assert.areEqual(1, result.keySet().size(), 'There should be 1 entry'); 
    }

}