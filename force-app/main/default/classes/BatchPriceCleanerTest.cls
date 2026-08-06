@isTest public with sharing class BatchPriceCleanerTest {
    
    @testSetup private static void testSetup() {
        DataFactoryProduct.createProducts();        
    }

    @isTest public static void testSAP() {
        List<PricebookEntry> entriesBefore = [select IsActive from PricebookEntry where isActive = false];
        Test.startTest();
        BatchPriceCleaner.executeInBatch();
        Test.stopTest();
        List<PricebookEntry> entriesAfter = [select IsActive from PricebookEntry where isActive = false];
        Integer newInactives = entriesAfter.size() + entriesBefore.size();
        System.assert(newInactives > 0, 'No new inactive entries found!');
    }

    @isTest public static void testSpecialsSAP() {
        Pricebook2 pb = [select Id, SAPCustomer__C from Pricebook2 limit 1][0];
        pb.SAPCustomer__c = 1;
        update pb;
        List<PricebookEntry> entriesBefore = [select IsActive from PricebookEntry where isActive = false];
        Test.startTest();
        BatchPriceCleaner.executeInBatch();
        Test.stopTest();
        List<PricebookEntry> entriesAfter = [select IsActive from PricebookEntry where isActive = false];
        Integer newInactives = entriesAfter.size() + entriesBefore.size();
        System.assert(newInactives > 0, 'No new inactive entries found!');
    }

}