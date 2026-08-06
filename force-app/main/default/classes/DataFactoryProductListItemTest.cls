@isTest public class DataFactoryProductListItemTest {
    
    @testSetup private static void testSetup() {
        ProductListItem__c[] items = DataFactoryProductListItem.createCollectionCaseItems();              
    }

    @isTest private static void createCollectionCaseItemsTest() {
        ProductListItem__c[] items = [select Id from ProductListItem__c];
        Assert.isTrue(items.size() > 0, 'Items should not be empty');
    }
    
}