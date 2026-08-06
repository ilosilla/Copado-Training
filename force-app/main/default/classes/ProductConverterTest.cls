@isTest public with sharing class ProductConverterTest {
    
    @testSetup private static void testSetup() {
        Product2[] changed = new List<Product2>();
        Product2[] products = DataFactoryProduct.createProducts(null);    
        
        // First product is going to be a tile
        products[0].Name = 'TILE';
        products[0].SalesUnit__c = 'CJ';
        products[0].StockUnit__c = 'PZS';
        products[0].UnitsXBox__c = 2.0;
        products[0].UnitsXM2__c = 1.398;
        products[0].UnitsXPal__c = 56.0;
        products[0].UnitWeight__c = 18.317;
        products[0].M2XBox__c = 1.43;
        products[0].PcsXBox__c = 2.0;
        products[0].BoxXPal__c = 28.0;
        changed.add(products[0]);

        // Second product a non tile in KG
        products[1].Name = 'NON-TILE';
        products[1].SalesUnit__c = 'KG';
        products[1].StockUnit__c = 'SAC';
        products[1].UnitWeight__c = 5;
        changed.add(products[1]);

        update changed;
    }

    @isTest private static void testTilesToStockUnit() {
        Product2 product = [select Id, ProductCode, Name from Product2 where Name = 'TILE' limit 1];
        ProductConverter converter = new ProductConverter(product.ProductCode);
        Double q1 = converter.convertToStockUnit(6, 'MT2');
        System.assertEquals(9, q1, '6 MT2 should be 9 pieces');

        Double sqf = 6 * ProductConverter.SQF_TO_METRES;
        Double q1b = converter.convertToStockUnit(sqf, 'SQF');
        System.assertEquals(9, q1b, 'Wrong conversion from SQF');


        Double q2 = converter.convertToStockUnit(6, 'CJ');
        System.assertEquals(12, q2, '6 CJ should be 12 pieces');

        Double q3 = converter.convertToStockUnit(6, 'PAL');
        System.assertEquals(336, q3, '6 PAL should be 336 pieces');

        ProductConverter.UKUnits uk = converter.convertToUKUnits(9, 'PZS');
        System.assertEquals(4, uk.boxes, '9 PZS should be 4 boxes');
        System.assertEquals(1, uk.pieces, '9 PZS should be 1 loose piece');
    }

    @isTest private static void testNonTilesToStockUnit() {
        Product2 product = [select Id, ProductCode, Name from Product2 where Name = 'NON-TILE' limit 1];
        ProductConverter converter = new ProductConverter(product.ProductCode);
        Double q1 = converter.convertToStockUnit(50, 'KG');
        System.assertEquals(10, q1, '50 KG should have been 10 SACS');
    }

    @isTest private static void testTilesFromToUnit() {
        Product2 product = [select Id, ProductCode, Name from Product2 where Name = 'TILE' limit 1];
        ProductConverter converter = new ProductConverter(product.ProductCode);
        Double q1 = converter.convertFromTo(6, 'CJ', 'PZS');
        System.assertEquals(12, q1, '6 BOX should be 12 pieces');

        Double q2 = converter.convertFromTo(6, 'PZS', 'CJ');
        System.assertEquals(3, q2, '6 PCS should be 3 BOX');

        Double q3 = converter.convertFromTo(56, 'PZS', 'PAL');
        System.assertEquals(1, q3, '56 PCS should be 1 PAL');

        Double q4 = converter.convertFromTo(2, 'PZS', 'MT2');
        System.assertEquals(1.43, q4, '2 PCS should be 1.43 MT2');

        Double q5 = converter.convertFromTo(2, 'PZS', 'SQF');
        Double sqf = 1.43 * 10.7639;
        System.assertEquals(sqf, q5, '2 PCS should be ' + sqf + ' SQF');
    }

    @isTest private static void testTilesToBoxes() {
        Product2 product = [select Id, ProductCode, Name from Product2 where Name = 'TILE' limit 1];
        ProductConverter converter = new ProductConverter(product.ProductCode);
        
        Double q1 = converter.convertToBoxes(2, 'PZS');
        System.assertEquals(1, q1, '2 PCS should be 1 BOX');

        q1 = converter.convertToBoxes(2, 'CJ');
        System.assertEquals(2, q1, '2 BOX should be 2 BOX');

        q1 = converter.convertToBoxes(1, 'PAL');
        System.assertEquals(28, q1, '1 PAL should be 28 BOX');

        q1 = converter.convertToBoxes(Double.valueOf(1.43), 'MT2');
        System.assertEquals(1, q1, '1.43 MT2 should be 1 BOX');

        Double sqf = 1.43 * 10.7639;
        q1 = converter.convertToBoxes(sqf, 'SQF');
        System.assertEquals(1, q1, sqf + ' SQF should be 1 BOX');
    }

    @isTest private static void testConstructor3() {
        Product2 product = [select Id, ProductCode, Name from Product2 where Name = 'TILE' limit 1];
        ProductConverter converter = new ProductConverter(product.Id);
        System.assert(converter!=null, 'It should not be null');
    }

}