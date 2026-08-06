@IsTest
private class B2B_ShippingRateServiceTest {

    @TestSetup
    static void setup() {
        User u = [select Id, Default_Sales_Organization__c from User where Id = :UserInfo.getUserId() limit 1];
        String salesOrg = u.Default_Sales_Organization__c;
        Assert.isNotNull(salesOrg, 'El usuario de test debe tener una Sales Org asignada en Default_Sales_Organization__c');

        B2BShippingRate__c rateUS1 = new B2BShippingRate__c(
            Store__c = 'USD_STORE',
            CountryCode__c = 'US',
            StateCode__c = 'CA',
            SalesOrg__c = salesOrg,
            ShippingMethod__c = 'US-STD',
            Weight__c = 2500,
            WeightUnit__c = 'LB',
            Amount__c = 115.00,
            CurrencyIsoCode = 'USD',
            Priority__c = 1,
            Active__c = true
        );

        B2BShippingRate__c rateUS2 = new B2BShippingRate__c(
            Store__c = 'USD_STORE',
            CountryCode__c = 'US',
            StateCode__c = 'CA',
            SalesOrg__c = salesOrg,
            ShippingMethod__c = 'US-UPS-60',
            Weight__c = 60,
            WeightUnit__c = 'LB',
            Amount__c = 55.00,
            CurrencyIsoCode = 'USD',
            Priority__c = 1,
            Active__c = true
        );
        insert new List<B2BShippingRate__c>{ rateUS1, rateUS2 };
    }

    @IsTest
    static void testGetRateForWeightBlocks_NumericPostcode_UPS() {
        Test.startTest();
        B2B_ShippingRateService.RateResultDTO result = 
            B2B_ShippingRateService.getRateForWeightBlocks('USD_STORE', 'US', 'CA', 22.68); // Peso en Kg
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Debería devolver un resultado');
        System.assertEquals(55.00, result.unitAmount, 'Unit amount incorrecto');
        System.assertEquals('USD', result.currencyCode, 'Moneda incorrecta');
        System.assertEquals(55.00, result.totalAmount, '1 bloque * 55.00 = 55.00');
    }

    @IsTest
    static void testGetRateForWeightBlocks_NumericPostcode_STD() {
        Test.startTest();
        B2B_ShippingRateService.RateResultDTO result = 
            B2B_ShippingRateService.getRateForWeightBlocks('USD_STORE', 'US', 'CA', 2315); // Peso en Kg
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Debería devolver un resultado');
        System.assertEquals(115.00, result.unitAmount, 'Unit amount incorrecto');
        System.assertEquals('USD', result.currencyCode, 'Moneda incorrecta');
        System.assertEquals(345.00, result.totalAmount, '3 bloques * 115.00 = 345.00');
    }

    @IsTest
    static void testGetRateForWeightBlocks_NumericPostcode_NO_MATCH() {
        Test.startTest();
        B2B_ShippingRateService.RateResultDTO result = 
            B2B_ShippingRateService.getRateForWeightBlocks('USD_STORE', 'US', 'AL', 2315); // Peso en Kg
        Test.stopTest();
        
        System.assertEquals(null, result, 'Debería devolver un resultado nulo');    
    }

}