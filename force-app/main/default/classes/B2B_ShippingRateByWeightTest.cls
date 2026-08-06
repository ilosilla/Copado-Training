@IsTest
private class B2B_ShippingRateByWeightTest {

    private static final String SALES_ORG   = 'US1';
    private static final String COUNTRY     = 'US';
    private static final String STATE_CA    = 'CA';
    private static final String STATE_AL    = 'AL';

    @TestSetup
    static void setup() {
        insert new List<B2BShippingRate__c>{
            new B2BShippingRate__c(
                Store__c          = 'USD_STORE',
                SalesOrg__c       = SALES_ORG,
                CountryCode__c    = COUNTRY,
                StateCode__c      = STATE_CA,
                ShippingMethod__c = 'US-UPS-60',
                Weight__c         = 60,
                WeightUnit__c     = 'LB',
                Amount__c         = 55.00,
                CurrencyIsoCode   = 'USD',
                Priority__c       = 1,
                Active__c         = true
            ),
            new B2BShippingRate__c(
                Store__c          = 'USD_STORE',
                SalesOrg__c       = SALES_ORG,
                CountryCode__c    = COUNTRY,
                StateCode__c      = STATE_CA,
                ShippingMethod__c = 'US-STD',
                Weight__c         = 2500,
                WeightUnit__c     = 'LB',
                Amount__c         = 115.00,
                CurrencyIsoCode   = 'USD',
                Priority__c       = 1,
                Active__c         = true
            )
        };
    }

    private static B2B_ShippingRateByWeight baseCalculator() {
        return new B2B_ShippingRateByWeight()
            .setSalesOrg(SALES_ORG)
            .setCountryCode(COUNTRY)
            .setStateCode(STATE_CA);
    }

    // ─── Happy path ──────────────────────────────────────────────────────────────

    @IsTest
    static void testCalculate_UPS() {
        Test.startTest();
        B2B_ShippingRateByWeight calc = baseCalculator()
            .setWeightKg(22.68)  // ~50 lb → UPS (≤60 lb)
            .calculate();
        Test.stopTest();

        Assert.isTrue(calc.getAvailable(), 'Debería estar disponible');
        Assert.areEqual(55.00, calc.getCost(), 'Cost incorrecto');
        Assert.areEqual('USD', calc.getCurrency(), 'Moneda incorrecta');
        Assert.isNotNull(calc.getExplanation(), 'Explanation no debería ser null');
        Assert.isNotNull(calc.getCarrierName(), 'CarrierName no debería ser null');
    }

    @IsTest
    static void testCalculate_STD() {
        Test.startTest();
        B2B_ShippingRateByWeight calc = baseCalculator()
            .setWeightKg(2500)  // ~5511 lb → 3 bloques de 2500 lb → 115 * 3 = 345
            .calculate();
        Test.stopTest();

        Assert.isTrue(calc.getAvailable(), 'Debería estar disponible');
        Assert.areEqual(345.00, calc.getCost(), 'Cost incorrecto');
        Assert.areEqual('USD', calc.getCurrency(), 'Moneda incorrecta');
    }

    // ─── No rule (available = false) ─────────────────────────────────────────────

    @IsTest
    static void testCalculate_noRule() {
        Test.startTest();
        B2B_ShippingRateByWeight calc = new B2B_ShippingRateByWeight()
            .setSalesOrg(SALES_ORG).setCountryCode(COUNTRY).setStateCode(STATE_AL).setWeightKg(100)
            .calculate();
        Test.stopTest();

        Assert.isFalse(calc.getAvailable(), 'Estado sin regla debe devolver available=false');
        Assert.isNotNull(calc.getExplanation(), 'Explanation debería tener mensaje de no disponibilidad');
    }

    // ─── Invalid inputs (IllegalArgumentException) ───────────────────────────────

    @IsTest
    static void testCalculate_nonUS() {
        Test.startTest();
        try {
            new B2B_ShippingRateByWeight()
                .setSalesOrg(SALES_ORG).setCountryCode('ES').setStateCode('B').setWeightKg(10)
                .calculate();
            Assert.fail('Debería haber lanzado IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('US'), 'Mensaje de error incorrecto');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCalculate_nullWeight() {
        Test.startTest();
        try {
            baseCalculator().setWeightKg(null).calculate();
            Assert.fail('Debería haber lanzado IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Debería tener mensaje de error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCalculate_zeroWeight() {
        Test.startTest();
        try {
            baseCalculator().setWeightKg(0).calculate();
            Assert.fail('Debería haber lanzado IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Debería tener mensaje de error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCalculate_blankSalesOrg() {
        Test.startTest();
        try {
            new B2B_ShippingRateByWeight()
                .setSalesOrg('').setCountryCode(COUNTRY).setStateCode(STATE_CA).setWeightKg(10)
                .calculate();
            Assert.fail('Debería haber lanzado IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Debería tener mensaje de error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCalculate_blankState() {
        Test.startTest();
        try {
            new B2B_ShippingRateByWeight()
                .setSalesOrg(SALES_ORG).setCountryCode(COUNTRY).setStateCode('').setWeightKg(10)
                .calculate();
            Assert.fail('Debería haber lanzado IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Debería tener mensaje de error');
        }
        Test.stopTest();
    }
}