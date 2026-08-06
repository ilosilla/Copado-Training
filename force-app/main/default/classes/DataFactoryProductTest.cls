@IsTest(IsParallel=false) public class DataFactoryProductTest {
    @isTest static void createProducts() {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        Product2[] products = DataFactoryProduct.createProducts();
        System.assertEquals(true, products.size()>0);
    }
}