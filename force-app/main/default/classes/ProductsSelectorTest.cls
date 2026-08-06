@isTest
public with sharing class ProductsSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryProduct.createProducts();
    }

    @isTest
    private static void selectById() {
        Set<Id> productIds = new Set<id>();
        for(Product2 l : [Select Id from Product2]) {
            productIds.add(l.id);
        }
        List<Product2> result = new ProductsSelector().selectById(productIds);
        System.assert(result.size() > 0, 'No se ha encontrado Product2 entry');
    }

    @isTest
    private static void selectByProductCode() {
        List<Product2> products = [Select Id, ProductCode from Product2];
        List<Product2> result = new ProductsSelector().selectByProductCode(new Set<String>{products[0].ProductCode});
        System.assert(result.size() == 1, 'No Se ha encontrado Product o mas de uno');
        System.assert(result[0].Id == products[0].Id, 'No es el mismo id');
    }

    @isTest
    private static void selectBySKU() {
        List<Product2> products = [Select Id, StockKeepingUnit from Product2];
        List<Product2> result = new ProductsSelector().selectBySKU(new Set<String>{products[0].StockKeepingUnit});
        System.assert(result.size() == 1, 'No Se ha encontrado Product o mas de uno');
        System.assert(result[0].Id == products[0].Id, 'No es el mismo id');
    }


    @isTest
    private static void selectAllString() {
        String result = new ProductsSelector().selectAllString();
        System.assert(result.startsWith('SELECT '), 'String SOQL no devuelto');
    }
}