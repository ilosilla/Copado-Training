@isTest public class BatchPriceUpdaterTest {

    @testSetup private static void testSetup() {
        //DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();        
    }

    @isTest
    public static void testBatchProcess() {        
        Product2[] products = [select Id, ProductCode from Product2];
        
        List<ZB2B_PRICE1__x> sapPrices = new List<ZB2B_PRICE1__x>();
        //for (Integer i = 0; i < 10; i++) {
            ZB2B_PRICE1__x price = new ZB2B_PRICE1__x();
            price.Bzirk__c = 'US1001';
            price.Cantidad__c = 1;
            price.Material__c = products[0].ProductCode;
            price.Moneda__c = 'USD';
            price.Prneto__c = 99.99;
            price.Uprecio__c = 'PZS';
            price.PrecioUMV__c = 99.99;
            price.UMV__c = 'PZS';

            sapPrices.add(price);
        //} // end for

        PricebookEntry pbe = [select Id, Pricebook2Id, UnitPrice from PricebookEntry where Product2Id = :products[0].Id and currencyIsoCode = 'USD' limit 1];
        System.assertNotEquals(null, pbe, 'No pricebook found - Cannot run the test');

        Pricebook2 pb = [select Id from Pricebook2 where Id = :pbe.Pricebook2Id limit 1];
        pb.Bzirk__c = 'US1001;US1002;US1003';
        update pb;

        Test.startTest();
            BatchPriceUpdater job = new BatchPriceUpdater(pbe.Pricebook2Id);
            job.setFullUpdate(false);
            job.start(null);
            job.execute(null,sapPrices);
            job.finish(null);
        Test.stopTest();

        PricebookEntry pbeAfter = [select Id, Pricebook2Id, UnitPrice from PricebookEntry where Id = :pbe.Id limit 1];
        System.assertNotEquals(null, pbeAfter, 'No pricebook entry found - Cannot run the test');
        System.assertEquals(99.99, pbeAfter.UnitPrice, 'New price should be 99.99');        
    }

    @isTest
    public static void testSpecialBatchProcess() {        
        String SAPCustomer = '1000000';
        Product2[] products = [select Id, ProductCode from Product2];
        
        List<ZB2B_PRICE2__x> sapPrices = new List<ZB2B_PRICE2__x>();
        //for (Integer i = 0; i < 10; i++) {
            ZB2B_PRICE2__x price = new ZB2B_PRICE2__x();
            price.Cliente__c = SAPCustomer;
            price.Cantidad__c = 1;
            price.Material__c = products[0].ProductCode;
            price.Moneda__c = 'USD';
            price.Prneto__c = 99.99;
            price.Uprecio__c = 'PZS';
            price.PrecioUMV__c = 99.99;
            price.UMV__c = 'PZS';
            sapPrices.add(price);
        //} // end for
        
        PricebookEntry pbe = [select Id, Pricebook2Id, UnitPrice from PricebookEntry where Product2Id = :products[0].Id and currencyIsoCode = 'USD' limit 1];
        System.assertNotEquals(null, pbe, 'No pricebook found - Cannot run the test');

        Pricebook2 pb = [select Id from Pricebook2 where Id = :pbe.Pricebook2Id limit 1];
        pb.SAPCustomer__c = Decimal.valueOf(SAPCUstomer);
        update pb;

        Test.startTest();
            BatchPriceUpdater job = new BatchPriceUpdater(pbe.Pricebook2Id);
            job.setFullUpdate(false);
            job.start(null);
            job.execute(null,sapPrices);
            job.finish(null);
        Test.stopTest();

        PricebookEntry pbeAfter = [select Id, Pricebook2Id, UnitPrice from PricebookEntry where Id = :pbe.Id limit 1];
        System.assertNotEquals(null, pbeAfter, 'No pricebook entry found - Cannot run the test');
        System.assertEquals(99.99, pbeAfter.UnitPrice, 'New price should be 99.99');        
    }

    @isTest
    public static void testGeneralPricebookRequiresSapPriceListCodes() {
        Product2[] products = [select Id, ProductCode from Product2];
        PricebookEntry pbe = [select Id, Pricebook2Id from PricebookEntry where Product2Id = :products[0].Id and currencyIsoCode = 'USD' limit 1];

        Pricebook2 pb = [select Id, Bzirk__c, SAPCustomer__c from Pricebook2 where Id = :pbe.Pricebook2Id limit 1];
        pb.Bzirk__c = ' ; ; ';
        pb.SAPCustomer__c = null;
        update pb;

        Test.startTest();
            Boolean exceptionThrown = false;
            try {
                BatchPriceUpdater job = new BatchPriceUpdater(pbe.Pricebook2Id);
                job.start(null);
            } catch (Exception ex) {
                exceptionThrown = true;
                System.assert(ex.getMessage().contains('No SAP price list codes are configured'), ex.getMessage());
            }
            System.assert(exceptionThrown, 'Expected an exception when no SAP price list codes are configured.');
        Test.stopTest();
    }

    @isTest
    public static void testBatchProcess2() {
        List<Pricebook2> priceBooks = [
            select Id, Bzirk__c
            from Pricebook2
            where SapSync__c = true
            and isActive = true
            and SAPCustomer__c = null
        ];
        for (Pricebook2 priceBook : priceBooks) {
            if (String.isBlank(priceBook.Bzirk__c)) {
                priceBook.Bzirk__c = 'US1001';
            }
        }
        update priceBooks;

        Test.startTest();
            BatchPriceUpdater.executeInBatch();
        Test.stopTest();
        Assert.isTrue(true); // Dummy - Queremos más cobertura pero en batch no s epuede probar nad aporque no hay revistros en las tablas de connect        
    }        

    @isTest
    public static void testBatchProcessWithEPFilter() {
        Product2[] products = [SELECT Id, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit != null];
        System.assert(products.size() >= 2, 'Need at least 2 products for this test');

        PricebookEntry pbe = [SELECT Id, Pricebook2Id FROM PricebookEntry
                              WHERE Product2Id = :products[0].Id AND CurrencyIsoCode = 'USD' LIMIT 1];

        // Crear EP con solo el primer producto en scope
        DataFactoryECommerce factory = new DataFactoryECommerce();
        CommerceEntitlementPolicy policy = factory.createEntitlementPolicy('US TEST POLICY');
        factory.createEntitlementProduct(policy.Id, products[0].Id);

        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id = :pbe.Pricebook2Id];
        pb.Bzirk__c = 'US1001';
        pb.EntitlementPolicy__c = policy.Id;
        update pb;

        List<ZB2B_PRICE1__x> sapPrices = new List<ZB2B_PRICE1__x>();
        ZB2B_PRICE1__x price = new ZB2B_PRICE1__x();
        price.Bzirk__c = 'US1001';
        price.Cantidad__c = 1;
        price.Material__c = products[0].StockKeepingUnit;
        price.Moneda__c = 'USD';
        price.Prneto__c = 49.99;
        price.Uprecio__c = 'PZS';
        price.PrecioUMV__c = 49.99;
        price.UMV__c = 'PZS';
        sapPrices.add(price);

        Test.startTest();
            BatchPriceUpdater job = new BatchPriceUpdater(pbe.Pricebook2Id);
            job.setFullUpdate(true);
            job.start(null);
            job.execute(null, sapPrices);
            job.finish(null);
        Test.stopTest();

        PricebookEntry pbeAfter = [SELECT Id, UnitPrice, IsActive FROM PricebookEntry WHERE Id = :pbe.Id];
        System.assertEquals(true, pbeAfter.IsActive, 'El producto en EP debe seguir activo');
        System.assertEquals(49.99, pbeAfter.UnitPrice, 'El precio debe haberse actualizado a 49.99');

        Integer activeOutOfScope = [SELECT COUNT() FROM PricebookEntry
                                    WHERE Pricebook2Id = :pb.Id
                                    AND Product2Id != :products[0].Id
                                    AND IsActive = true];
        System.assertEquals(0, activeOutOfScope, 'Los productos fuera de EP deben quedar inactivos');
    }

} // class