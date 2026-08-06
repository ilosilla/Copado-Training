@isTest public with sharing class ProductListItemsSelectorTest {

    @testSetup private static void testSetup() {
        DataFactoryProductListItem.createCollectionCaseItems();
    }

    @IsTest private static void selectById() {
        List<ProductListItem__c> items = [select Id from ProductListItem__c];
        Set<Id> ids = new Set<Id>();
        for (ProductListItem__c item : items) {
            ids.add(item.Id);
        }
        ProductListItemsSelector selector = new ProductListItemsSelector();
        List<ProductListItem__c> results = selector.selectById(ids);
        Assert.areEqual(ids.size(), results.size(), 'Wrong number of results');

        // Probar que funciona la lista de campos que devuelve
        Assert.isNotNull(results[0].ProductCode__c, 'FIeld should have a value');
    }

    @IsTest private static void selectSingle() {
        ProductListItem__c item = [select Id from ProductListItem__c limit 1];
        ProductListItemsSelector selector = new ProductListItemsSelector();
        ProductListItem__c result = (ProductListItem__c) selector.selectSingle(item.Id);
        Assert.areEqual(item.Id, result.Id, 'Should be the same record');        
    }

    @IsTest private static void selectByCase() {
        Case c = [select Id from Case limit 1];
        ProductListItemsSelector selector = new ProductListItemsSelector();
        ProductListItem__c[] results = selector.selectByCase(new Set<Id>{c.Id});
        Assert.isTrue(results.size() > 0, 'List items cannot be empty');        
    }
    @isTest 
    private static void testAddField() {
        List<ProductListItem__c> items = [select Id from ProductListItem__c];
        Set<Id> ids = new Set<Id>();
        for (ProductListItem__c item : items) {
            ids.add(item.Id);
        }
        ProductListItemsSelector selector = new ProductListItemsSelector();
        selector.addRelationshipField('Product__r.Name');        
        List<ProductListItem__c> results = selector.selectById(ids);
        Assert.isTrue(results.size() > 0, 'The list should not be empty');

        // Probar que funciona la lista de campos que devuelve
        Assert.isNotNull(results[0].Product__r.Name, 'Field should have a value');
    }

}