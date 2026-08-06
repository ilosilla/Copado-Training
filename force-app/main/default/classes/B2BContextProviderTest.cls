@IsTest
private class B2BContextProviderTest {

    @TestSetup
    static void setup() {
        Account acc = DataFactoryAccount.createAccounts(1)[0];
        DataFactoryOrganization.createData();

        Sales_Org__c[] orgs = [SELECT Id FROM Sales_Org__c WHERE SalesOrg__c = '605' LIMIT 1];
        Assert.isTrue(orgs.size() > 0, 'Test setup failed: Sales Org not found');

        B2BMarketSettings__c market = new B2BMarketSettings__c(
            Name                = 'US_DEALERS',
            Label__c            = 'US Dealers',
            CurrencyIsoCode     = 'USD',
            CountryCode__c      = 'US',
            CheckoutMode__c     = 'REGION',
            ValidatePrices__c   = true,
            StockDisplay__c     = 'QUANTITY',
            ShadeEnabled__c        = true,
            PalletSurchargeMode__c = 'NOT_APPLICABLE',
            Active__c              = true
        );
        insert market;

        insert new B2BAccountSettings__c(
            AccountId__c           = acc.Id,
            Market__c              = market.Id,
            SalesOrgId__c          = orgs[0].Id,
            CreditCardAllowed__c   = true,
            CreditCardSurcharge__c = 2.5,
            NotifyOrderTo__c       = 'CUSTOMER',
            PricingMode__c          = 'DEFERRED',
            Active__c              = true
        );
    }

    @IsTest
    static void testGetContext_returnsContext() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        B2BContextProvider.B2BContext ctx = B2BContextProvider.getContext(acc.Id, null);
        Test.stopTest();

        Assert.isNotNull(ctx, 'Context should not be null');
        Assert.areEqual(acc.Id, ctx.effectiveAccountId, 'Account Id mismatch');
        Assert.areEqual('605', ctx.salesOrg, 'SalesOrg mismatch');
        Assert.isNotNull(ctx.cacheVersion, 'Cache version should not be null');

        // Account settings
        Assert.isNotNull(ctx.account, 'Account settings should not be null');
        Assert.isTrue(ctx.account.creditCardAllowed, 'Credit card should be allowed');
        Assert.areEqual(2.5, ctx.account.creditCardSurcharge, 'Surcharge mismatch');
        Assert.areEqual('CUSTOMER', ctx.account.notifyOrderTo, 'NotifyOrderTo mismatch');
        Assert.isFalse(ctx.account.showPrices, 'showPrices should be false (PricingMode = DEFERRED, only LIVE shows prices)');
        Assert.isTrue(ctx.account.deferredPricing, 'deferredPricing should be true (PricingMode = DEFERRED)');

        // Market settings
        Assert.isNotNull(ctx.market, 'Market settings should not be null');
        Assert.areEqual('US_DEALERS', ctx.market.name, 'Market name mismatch');
        Assert.areEqual('US Dealers', ctx.market.label, 'Market label mismatch');
        Assert.areEqual('US', ctx.market.countryCode, 'Country code mismatch');
        Assert.areEqual('USD', ctx.market.currencyIsoCode, 'Currency mismatch');
        Assert.isFalse(ctx.market.isDirectCustomer, 'Should not be direct customer');
        Assert.isTrue(ctx.market.validatePrices, 'ValidatePrices mismatch');
        Assert.isNotNull(ctx.market.id, 'Market Id should not be null');
        Assert.isTrue(ctx.market.showStock, 'showStock should be true (StockDisplay = QUANTITY)');
        Assert.isTrue(ctx.market.stockAsQuantity, 'stockAsQuantity should be true (StockDisplay = QUANTITY)');
        Assert.isTrue(ctx.market.shadeEnabled, 'shadeEnabled should be true');
        Assert.areEqual('NOT_APPLICABLE', ctx.market.palletSurchargeMode, 'palletSurchargeMode mismatch');

        // Pricing context — pricebookId is null because buyerGroupId is null in test
        Assert.isNotNull(ctx.pricing, 'Pricing context should not be null');
        Assert.isNull(ctx.pricing.pricebookId, 'pricebookId should be null when buyerGroupId is null');
    }

    @IsTest
    static void testGetContext_directCustomer_returnsGenericWarehouse() {
        Account acc = DataFactoryAccount.createAccounts(1)[0];

        B2BMarketSettings__c market = new B2BMarketSettings__c(
            Name                = 'IE_DIRECT',
            Label__c            = 'Ireland Direct',
            CurrencyIsoCode     = 'EUR',
            CountryCode__c      = 'IE',
            CheckoutMode__c     = 'FACTORY',
            StockDisplay__c     = 'QUANTITY',
            ShadeEnabled__c     = true,
            Active__c           = true
        );
        insert market;

        insert new B2BAccountSettings__c(
            AccountId__c  = acc.Id,
            Market__c     = market.Id,
            PricingMode__c = 'LIVE',
            Active__c     = true
        );

        Test.startTest();
        B2BContextProvider.B2BContext ctx = B2BContextProvider.getContext(acc.Id, null);
        Test.stopTest();

        Assert.isTrue(ctx.market.isDirectCustomer, 'Should be direct customer');
        Assert.isNull(ctx.salesOrg, 'salesOrg should be null for direct customer');
        Assert.areEqual(B2BContextProvider.DIRECT_CUSTOMER_NAME, ctx.salesOrgName, 'salesOrgName mismatch');
        Assert.isNotNull(ctx.warehouse, 'Warehouse should not be null for direct customer');
        Assert.areEqual(B2BContextProvider.DIRECT_CUSTOMER_NAME, ctx.warehouse.name, 'Warehouse name mismatch');
        Assert.isNotNull(ctx.warehouse.formattedAddress, 'Formatted address should not be null');
        Assert.isNull(ctx.warehouse.contactLine, 'Contact line should be null for direct customer');
        // Pricing context — showPrices=true (LIVE) but no buyerGroupId → pricebookId null
        Assert.isNotNull(ctx.pricing, 'Pricing context should not be null');
        Assert.isNull(ctx.pricing.pricebookId, 'pricebookId should be null when no buyerGroupId');
        // Stock: showStock=true but no SAP_Plants__x records in test org → stock null
        Assert.isNull(ctx.stock, 'stock should be null when no factory plants found');
    }

    @IsTest
    static void testGetContext_nullAccountId_throws() {
        Test.startTest();
        try {
            B2BContextProvider.getContext(null, null);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetContext_noSettings_throws() {
        Account acc = DataFactoryAccount.createAccounts(1)[0];

        Test.startTest();
        try {
            B2BContextProvider.getContext(acc.Id, null);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetPaymentSettings_returnsSettings() {
        B2BPaymentSettings__c ps = new B2BPaymentSettings__c(
            Name                 = 'US Payment',
            PaymentGatewayURL__c = 'https://gateway.example.com',
            MerchantID__c        = 'MERCHANT_001',
            Secret__c            = 'secret123'
        );
        insert ps;

        Test.startTest();
        B2BPaymentSettings__c result = B2BContextProvider.getPaymentSettings(ps.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return payment settings');
        Assert.areEqual('https://gateway.example.com', result.PaymentGatewayURL__c, 'Gateway URL mismatch');
        Assert.areEqual('MERCHANT_001', result.MerchantID__c, 'MerchantID mismatch');
    }

    @IsTest
    static void testGetPaymentSettings_nullId_returnsNull() {
        Test.startTest();
        B2BPaymentSettings__c result = B2BContextProvider.getPaymentSettings(null);
        Test.stopTest();

        Assert.isNull(result, 'Should return null for null Id');
    }

    @IsTest
    static void testBuildContactLine_bothValues() {
        String result = B2BContextProvider.buildContactLine('+1 555 000 111', 'test@example.com');
        Assert.areEqual('+1 555 000 111 · test@example.com', result, 'Both values should be joined');
    }

    @IsTest
    static void testBuildContactLine_phoneOnly() {
        String result = B2BContextProvider.buildContactLine('+1 555 000 111', null);
        Assert.areEqual('+1 555 000 111', result, 'Should return phone only');
    }

    @IsTest
    static void testBuildContactLine_emailOnly() {
        String result = B2BContextProvider.buildContactLine(null, 'test@example.com');
        Assert.areEqual('test@example.com', result, 'Should return email only');
    }

    @IsTest
    static void testBuildContactLine_neitherValue_returnsNull() {
        String result = B2BContextProvider.buildContactLine(null, null);
        Assert.isNull(result, 'Should return null when both are blank');
    }

    @IsTest
    static void testBuildStockFromData_buildsDTO() {
        List<String> plantCodes = new List<String>{ '603', '604' };
        List<SAP_StockWarehouses__x> whRecs = new List<SAP_StockWarehouses__x>{
            new SAP_StockWarehouses__x(Plant__c = '603', Warehouse__c = '0001'),
            new SAP_StockWarehouses__x(Plant__c = '603', Warehouse__c = '0050'),
            new SAP_StockWarehouses__x(Plant__c = '604', Warehouse__c = '0002'),
            new SAP_StockWarehouses__x(Plant__c = '604', Warehouse__c = null)   // null → ignorado
        };

        Map<String, String> companyByPlant = new Map<String, String>{ '603' => '610', '604' => '004' };

        B2BContextProvider.StockContextDTO stock = B2BContextProvider.buildStockFromData(plantCodes, whRecs, companyByPlant);

        Assert.isNotNull(stock, 'Stock should not be null');
        Assert.areEqual(2, stock.plants.size(), 'Should have 2 plants');

        B2BContextProvider.PlantDTO p603 = stock.plants[0];
        Assert.areEqual('603', p603.plant, 'First plant should be 603');
        Assert.areEqual('610', p603.company, 'Plant 603 company should be resolved');
        Assert.areEqual(2, p603.warehouses.size(), 'Plant 603 should have 2 warehouses');
        Assert.isTrue(p603.warehouses.contains('0001'), 'Should contain warehouse 0001');
        Assert.isTrue(p603.warehouses.contains('0050'), 'Should contain warehouse 0050');

        B2BContextProvider.PlantDTO p604 = stock.plants[1];
        Assert.areEqual('604', p604.plant, 'Second plant should be 604');
        Assert.areEqual('004', p604.company, 'Plant 604 company should be resolved');
        Assert.areEqual(1, p604.warehouses.size(), 'Plant 604 should have 1 warehouse (null ignored)');
    }

    @IsTest
    static void testBuildStockFromData_noWarehouses_returnsNull() {
        List<String> plantCodes = new List<String>{ '603' };
        List<SAP_StockWarehouses__x> whRecs = new List<SAP_StockWarehouses__x>();

        B2BContextProvider.StockContextDTO stock = B2BContextProvider.buildStockFromData(plantCodes, whRecs, new Map<String, String>());

        Assert.isNull(stock, 'Stock should be null when no warehouses match');
    }

    @IsTest
    static void testGetContext_withWarehouse_returnsWarehouseData() {
        insert new PorcelanosaAddress__c(
            Name                = 'US Warehouse',
            NBK_SAPId__c        = 'US1_WH',
            SAPSalesOrg__c      = '605',
            NBK_isActive__c     = true,
            NBK_Address_Type__c = 'B2B-Warehouse',
            NBK_Phone__c        = '+1 555 000 111',
            Email__c            = 'us@porcelanosa.com'
        );

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        B2BContextProvider.B2BContext ctx = B2BContextProvider.getContext(acc.Id, null);
        Test.stopTest();

        Assert.isNotNull(ctx.warehouse, 'Warehouse should not be null');
        Assert.areEqual('US Warehouse', ctx.warehouse.name, 'Warehouse name mismatch');
        Assert.isNotNull(ctx.warehouse.formattedAddress, 'Formatted address should not be null');
        Assert.isNotNull(ctx.warehouse.contactLine, 'Contact line should not be null');
    }

    @IsTest
    static void testGetContext_resolvesPricebookFromBuyerGroup() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        BuyerGroup bg = new BuyerGroup(Name = 'Test Buyer Group');
        insert bg;

        Pricebook2 pb = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert pb;

        insert new BuyerGroupPricebook(
            BuyerGroupId = bg.Id,
            Pricebook2Id = pb.Id,
            IsActive     = true
        );

        Test.startTest();
        B2BContextProvider.B2BContext ctx = B2BContextProvider.getContext(acc.Id, bg.Id);
        Test.stopTest();

        Assert.isNotNull(ctx.pricing, 'Pricing context should not be null');
        Assert.areEqual(pb.Id, ctx.pricing.pricebookId, 'pricebookId should resolve from the BuyerGroupPricebook');
    }
}