@isTest public class ProductsSelectorV2Test {

    @testSetup private static void testSetup() {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();
    }

    @isTest private static void test001() {
        ProductsSelectorV2 selector = new ProductsSelectorV2();
        selector.addRelationshipField('SAPItemGroup__r.SAPGroup__c');
        List<Product2> products = (List<Product2>) selector.selectAll();
        Assert.isTrue(products.size()>0, 'Number of products not correct');

        List<Product2> products2 = selector.selectBySKU(new Set<String>{products[0].StockKeepingUnit});
        Assert.areEqual(1, products2.size(), 'Number of products by SKU not correct');
    }
}