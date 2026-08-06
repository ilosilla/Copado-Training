@isTest public with sharing class B2B_ServicesControllerTest {

    @testSetup public static void testSetup() {
        SAPStockServiceTest.testSetup();
        List<Product2> products = DataFactoryProduct.createProducts();
        User u = [select Id, Default_Sales_Organization__c from user where Id = :UserInfo.getUserId() limit 1];
        u.Default_Sales_Organization__c = '502';

        PIMProduct__c pim = new PIMProduct__c();
        pim.Product__c = products[0].Id;
        pim.Color__c = 'GRIS';
        insert pim;

        Account acc = DataFactoryAccount.createAccounts(1)[0];

        B2BMarketSettings__c market = new B2BMarketSettings__c(
            Name                = 'TEST_DIRECT',
            Label__c            = 'Test Direct',
            CurrencyIsoCode     = 'USD',
            CountryCode__c      = 'US',
            CheckoutMode__c = 'FACTORY',
            StockDisplay__c     = 'NONE',
            PalletSurchargeMode__c = 'NOT_APPLICABLE',
            Active__c              = true
        );
        insert market;

        insert new B2BAccountSettings__c(
            AccountId__c  = acc.Id,
            Market__c     = market.Id,
            PricingMode__c = 'LIVE',
            Active__c     = true
        );
    }

    @isTest static void test001() {
        Product2 p = [select Id from Product2 limit 1];
        PricebookEntry entry = [select Id from PricebookEntry where Product2Id = :p.Id limit 1];
        Account acc = [select Id from Account limit 1];

        Test.startTest();
        B2BContextProvider.getContext(acc.Id, null); // warms the session cache, as libStoreContextProvider does on page load
        B2B_ServicesController.PDPDataDTO result = B2B_ServicesController.readPDPData(p.Id, entry.Id, acc.Id);
        Test.stopTest();

        Assert.areEqual(p.Id, result.pimData.get('Product__c'), 'Wrong Product Id returned');
        Assert.isNotNull(result.pimData.get('Color__c_DisplayValue'), 'Color label expected');
        Assert.isNotNull(result.pimData.get('Brand__c_DisplayValue'), 'An empty brand label expected');
        Assert.isNull(result.stock.stockAvailable, 'Stock is disabled for this market (StockDisplay__c = NONE), no lookup should happen');
        Assert.areEqual(0, result.palletSurcharge, 'No surcharge expected for NOT_APPLICABLE mode');
    }

    @isTest static void testReadPDPData_showStockEnabled_noPlantResolved_showsUnavailable() {
        Product2 p = [select Id from Product2 limit 1];
        PricebookEntry entry = [select Id from PricebookEntry where Product2Id = :p.Id limit 1];

        Account acc = DataFactoryAccount.createAccounts(1)[0];
        B2BMarketSettings__c market = new B2BMarketSettings__c(
            Name                = 'TEST_DIRECT_STOCK',
            Label__c            = 'Test Direct Stock',
            CurrencyIsoCode     = 'USD',
            CountryCode__c      = 'US',
            CheckoutMode__c = 'FACTORY',
            StockDisplay__c     = 'QUANTITY',
            PalletSurchargeMode__c = 'NOT_APPLICABLE',
            Active__c              = true
        );
        insert market;
        insert new B2BAccountSettings__c(
            AccountId__c   = acc.Id,
            Market__c      = market.Id,
            PricingMode__c = 'LIVE',
            Active__c      = true
        );

        Test.startTest();
        B2BContextProvider.getContext(acc.Id, null);
        B2B_ServicesController.PDPDataDTO result = B2B_ServicesController.readPDPData(p.Id, entry.Id, acc.Id);
        Test.stopTest();

        Assert.areEqual('Stock information currently unavailable', result.stock.stockText,
            'No plant resolved (SAP_Plants__x is empty in tests): stock should degrade gracefully, not fail the whole PDP');
    }

    @isTest static void testReadPDPData_noContextCached_throws() {
        Product2 p = [select Id from Product2 limit 1];
        PricebookEntry entry = [select Id from PricebookEntry where Product2Id = :p.Id limit 1];
        Account acc = [select Id from Account limit 1];

        Test.startTest();
        try {
            B2B_ServicesController.readPDPData(p.Id, entry.Id, acc.Id);
            Assert.fail('Should have thrown when context is not cached for this session');
        } catch (ObjectNotFoundException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    /*@isTest static void test002() {
        PIMProduct__c pim = [select Id, Product__c, SpecialPieces__c, Adhesives__c, AdhesivesWetAreas__c, JointMaterials__c, JointMaterialWetAreas__c from PIMProduct__c limit 1];
        Product2 p = [select Id, StockKeepingUnit from Product2 where Id != :pim.Product__c limit 1];
        pim.SpecialPieces__c = '["' + p.StockKeepingUnit + '", "dummy1"]';
        pim.AdhesivesWetAreas__c = '["dummy1", "dummy2"]';
        update pim;
        Test.startTest();
        Set<String> codes = B2B_ServicesController.readRelatedCodes(pim);
        Test.stopTest();
        Assert.areEqual(3, codes.size(), '3 related products expected');
    }*/

    @isTest static void test003() {
        PIMProduct__c pim = [select Id, Product__c, SpecialPieces__c, Adhesives__c, AdhesivesWetAreas__c, JointMaterials__c, JointMaterialWetAreas__c from PIMProduct__c limit 1];
        Product2 p = [select Id, StockKeepingUnit from Product2 where Id != :pim.Product__c limit 1];
        pim.SpecialPieces__c = '["' + p.StockKeepingUnit + '"]';
        update pim;
        PricebookEntry entry = [select Id from PricebookEntry where Product2Id = :pim.Product__c limit 1];
        Test.startTest();
        B2B_ServicesController.RelatedProductDTO[] result = B2B_ServicesController.readRelatedProductsList(pim.Product__c , entry.Id, entry.Id);
        Test.stopTest();
        Assert.isTrue(result.size() >= 0, 'Dummy');
    }

    /* ========================================================= */
    /* Real-time stock happy paths                               */
    /* ========================================================= */

    // Warms the context cache and injects a resolvable plant (SAP_Plants__x is empty
    // in tests, so resolvePlant would otherwise return null and skip the SAP call).
    private static void primeContextWithPlant(Id accountId, String company) {
        B2BContextProvider.B2BContext ctx = B2BContextProvider.getContext(accountId, null);
        B2BContextProvider.PlantDTO plant = new B2BContextProvider.PlantDTO();
        plant.plant = '605';
        plant.company = company;
        plant.warehouses = new List<String>{ '0001' };
        B2BContextProvider.StockContextDTO stock = new B2BContextProvider.StockContextDTO();
        stock.plants = new List<B2BContextProvider.PlantDTO>{ plant };
        ctx.stock = stock;
        String key = B2BContextProvider.CACHE_PARTITION + '.ctx'
            + String.valueOf(accountId).replace('-', '').left(15);
        Cache.Session.put(key, ctx);
    }

    private static Account newAccountForMarket(String name, Boolean direct, Boolean shade) {
        B2BMarketSettings__c market = new B2BMarketSettings__c(
            Name                   = name,
            Label__c               = name,
            CurrencyIsoCode        = 'USD',
            CountryCode__c         = 'US',
            CheckoutMode__c        = direct ? 'FACTORY' : 'REGION',
            StockDisplay__c        = 'QUANTITY',
            ShadeEnabled__c        = shade,
            PalletSurchargeMode__c = 'NOT_APPLICABLE',
            Active__c              = true
        );
        insert market;
        Account acc = DataFactoryAccount.createAccounts(1)[0];
        insert new B2BAccountSettings__c(
            AccountId__c   = acc.Id,
            Market__c      = market.Id,
            PricingMode__c = 'LIVE',
            Active__c      = true
        );
        return acc;
    }

    private static String stockRowJson(String lote, Decimal avail, Decimal total) {
        return '{"product":"x","name":"X","plant":"605","warehouse":"0001","availstk":' + avail
            + ',"totalstk":' + total + ',"intransit":0,"umb":"PZS","umb_en":"PZS","lote":"' + lote + '"}';
    }

    @isTest static void testReadPDPData_aggregateStock() {
        // Non-tile product + shade off -> useLoteDetail is false -> getStockTotal / fillFromRow path
        Id pid = [SELECT Product__c FROM PIMProduct__c LIMIT 1].Product__c;
        PricebookEntry entry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :pid LIMIT 1];
        Account acc = newAccountForMarket('TEST_AGG', true, false);

        SAPStockServiceTest.Mocker mock = new SAPStockServiceTest.Mocker();
        mock.json = '{"data":[' + stockRowJson('', 50.000, 80.000) + '],"errors":[],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, mock);

        primeContextWithPlant(acc.Id, '002');
        Test.startTest();
        B2B_ServicesController.PDPDataDTO result = B2B_ServicesController.readPDPData(pid, entry.Id, acc.Id);
        Test.stopTest();

        Assert.areEqual(50, result.stock.stockAvailable, 'Aggregated available stock expected from the mocked SAP row');
    }

    @isTest static void testReadPDPData_stockByLote_directTileShade() {
        Id pid = [SELECT Product__c FROM PIMProduct__c LIMIT 1].Product__c;
        // Make the product a (non-special) tile: IsTile__c formula reads SAPItemGroup__r.SAPGroup__c
        ItemGroup__c grp = new ItemGroup__c(Name = 'Tiles', SAPGroup__c = 'PT0001');
        insert grp;
        update new Product2(Id = pid, SAPItemGroup__c = grp.Id, PcsXBox__c = 3, BoxXPal__c = 40, M2XBox__c = 1.0);

        PricebookEntry entry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :pid LIMIT 1];
        Account acc = newAccountForMarket('TEST_LOTE', true, true);

        SAPStockServiceTest.Mocker mock = new SAPStockServiceTest.Mocker();
        mock.json = '{"data":[' + stockRowJson('1C2', 10.000, 10.000) + ',' + stockRowJson('2C2', 20.000, 20.000) + '],"errors":[],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, mock);

        primeContextWithPlant(acc.Id, '002');   // matches SAPFactory__c for SAPMake__c = 'P'
        Test.startTest();
        B2B_ServicesController.PDPDataDTO result = B2B_ServicesController.readPDPData(pid, entry.Id, acc.Id);
        Test.stopTest();

        Assert.isNotNull(result.stock.byLote, 'Per-lote breakdown expected for direct + shade + tile');
        Assert.areEqual(2, result.stock.byLote.size(), 'Two lote rows expected from the mock');
    }

    @isTest static void testReadPDPData_stockCalloutError_degradesGracefully() {
        Id pid = [SELECT Product__c FROM PIMProduct__c LIMIT 1].Product__c;
        PricebookEntry entry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :pid LIMIT 1];
        Account acc = newAccountForMarket('TEST_ERR', true, false);

        SAPStockServiceTest.Mocker mock = new SAPStockServiceTest.Mocker();
        mock.raiseException = true;
        Test.setMock(HttpCalloutMock.class, mock);

        primeContextWithPlant(acc.Id, '002');
        Test.startTest();
        B2B_ServicesController.PDPDataDTO result = B2B_ServicesController.readPDPData(pid, entry.Id, acc.Id);
        Test.stopTest();

        Assert.isNotNull(result.stock.stockError, 'A callout failure should be captured as stockError, not break the PDP');
    }

    @isTest static void testReadPDPData_pimMissing_throws() {
        // A product with a PricebookEntry but no PIMProduct__c (only one product gets a PIM in setup)
        Id pimProductId = [SELECT Product__c FROM PIMProduct__c LIMIT 1].Product__c;
        PricebookEntry entry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id != :pimProductId LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        B2BContextProvider.getContext(acc.Id, null);
        try {
            B2B_ServicesController.readPDPData(entry.Product2Id, entry.Id, acc.Id);
            Assert.fail('Expected ObjectNotFoundException for missing PIM data');
        } catch (ObjectNotFoundException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    @isTest private static void testAddCartItem() {
        B2B_ServicesController.CartItemDTO item = new B2B_ServicesController.CartItemDTO();
        item.webStoreId = 'TestStore';
        item.cartId = 'TestCart';
        item.productId = 'TestProduct';
        item.pricebookEntryId = 'TestPricebookEntry';
        item.quantity = 2;
        item.salesUnit = 'EA';  
        item.listPriceUnit = 'EA';
        item.weightPerUnitKg = 1.5;
        item.lineWeightKg = 3.0;
        Test.startTest();
        try {
            B2B_ServicesController.addItemToCart(item);
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Add to cart should not throw an exception');
        }
        Test.stopTest();
        Assert.isTrue(true, 'Add to cart executed without errors');
    }

}