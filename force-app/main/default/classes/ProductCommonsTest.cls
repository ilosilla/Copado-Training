@isTest public class ProductCommonsTest {

    @isTest private static void testNormalizeMake() {
        Test.startTest();
        String make1 = 'Sin marca';
        String make2 = 'SIN MARCA';
        String make3 = 'sIN mARCa';
        String make4 = 'Honda';
        String make5 = '';

        System.assertEquals('', ProductCommons.normalizeMake(make1), 'make1 should be ""');
        System.assertEquals('', ProductCommons.normalizeMake(make2), 'make2 should be ""');
        System.assertEquals('', ProductCommons.normalizeMake(make3), 'make3 should be ""');
        System.assertEquals('HONDA', ProductCommons.normalizeMake(make4), 'make4 should be "HONDA"');
        System.assertEquals(make5, ProductCommons.normalizeMake(make5), 'make5 should be unchanged');
        Test.stopTest();
    }
    @isTest private static void testMakeCodeFromName() {
        Test.startTest();
        String make1 = 'KRION';
        String make2 = 'URBATEK';
        String make3 = 'SIN MARCA';
        String make4 = 'HONDA';
        String make5 = '';

        System.assertEquals('S', ProductCommons.makeCodeFromName(make1), 'make1 should be "S"');
        System.assertEquals('C', ProductCommons.makeCodeFromName(make2), 'make2 should be "C"');
        System.assertEquals('', ProductCommons.makeCodeFromName(make3), 'make3 should be ""');
        System.assertEquals('H', ProductCommons.makeCodeFromName(make4), 'make4 should be "H"');
        System.assertEquals(make5, ProductCommons.makeCodeFromName(make5), 'make5 should be unchanged');
        Test.stopTest();
    }

    @isTest private static void testStockProgram(){
        DataFactoryProduct.skipPriceBooks = true;
        Product2[] products = DataFactoryProduct.createProducts();
        Set<String> skus = new Set<String>();
        for (product2 p : products){      
            skus.add(p.StockKeepingUnit); 
        }
        Boolean result = ProductCommons.checkStockProgram('502', skus);
        Assert.isTrue(result, 'Should be true');
    }  
}