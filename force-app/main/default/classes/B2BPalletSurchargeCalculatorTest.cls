@IsTest
private class B2BPalletSurchargeCalculatorTest {

    /* ================================================================== */
    /* Helpers                                                              */
    /* ================================================================== */

    private static ZSFDesPalet__x rowWithRate(Decimal rate, String hierarchy) {
        ZSFDesPalet__x row = new ZSFDesPalet__x();
        row.CurrencyCode__c     = '%';
        row.ConditionRate__c    = rate;
        row.ProductHierarchy__c = hierarchy;
        return row;
    }

    private static B2BPalletSurchargeCalculator calcWithRate(Decimal rate, String hierarchy) {
        return new B2BPalletSurchargeCalculator(rowWithRate(rate, hierarchy));
    }

    /* ================================================================== */
    /* Constructor — NOT_APPLICABLE                                         */
    /* ================================================================== */

    @IsTest
    static void testNotApplicable_rateIsZero() {
        B2BContextProvider.B2BContext ctx = new B2BContextProvider.B2BContext();
        B2BPalletSurchargeCalculator calc = new B2BPalletSurchargeCalculator('NOT_APPLICABLE', ctx);

        Assert.areEqual(0, calc.computeSurcharge('00100300010001', true, false),
            'NOT_APPLICABLE: surcharge should be 0');
    }

    /* ================================================================== */
    /* Constructor (@TestVisible) — rate loading                           */
    /* ================================================================== */

    @IsTest
    static void testValidRate_setsRate() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');
        Assert.areEqual(15.0, calc.computeSurcharge('00100300010001', true, false),
            'Rate 15% should be applied for matching hierarchy');
    }

    @IsTest
    static void testNullConditionRate_returnsZero() {
        B2BPalletSurchargeCalculator calc = calcWithRate(null, '001003');
        Assert.areEqual(0, calc.computeSurcharge('00100300010001', true, false),
            'Null ConditionRate__c should yield 0');
    }

    @IsTest
    static void testInvalidCurrency_throwsException() {
        ZSFDesPalet__x row = new ZSFDesPalet__x();
        row.CurrencyCode__c     = 'EUR';
        row.ConditionRate__c    = 15.0;
        row.ProductHierarchy__c = '001003';

        try {
            new B2BPalletSurchargeCalculator(row);
            Assert.fail('Expected InvalidRateException');
        } catch (B2BPalletSurchargeCalculator.InvalidRateException e) {
            Assert.isTrue(e.getMessage().contains('EUR'),
                'Exception message should include the invalid currency code');
        }
    }

    /* ================================================================== */
    /* computeSurcharge — rama jerarquía (productHierarchy presente)       */
    /* ================================================================== */

    @IsTest
    static void testComputeSurcharge_hierarchyMatch_returnsRate() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');
        Assert.areEqual(15.0, calc.computeSurcharge('00100300010001', true, false),
            'Jerarquia starting with prefix → rate');
    }

    @IsTest
    static void testComputeSurcharge_hierarchyExactMatch_returnsRate() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');
        Assert.areEqual(15.0, calc.computeSurcharge('001003', true, false),
            'Exact prefix match → rate');
    }

    @IsTest
    static void testComputeSurcharge_hierarchyNoMatch_returnsZero() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');
        Assert.areEqual(0, calc.computeSurcharge('00200100010001', true, false),
            'Jerarquia not starting with prefix → 0');
    }

    @IsTest
    static void testComputeSurcharge_nullJerarquia_withHierarchy_returnsZero() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');
        Assert.areEqual(0, calc.computeSurcharge(null, true, false),
            'Null Jerarquia__c con productHierarchy → 0');
    }

    /* ================================================================== */
    /* computeSurcharge — rama fallback (productHierarchy en blanco)       */
    /* ================================================================== */

    @IsTest
    static void testComputeSurcharge_noHierarchy_tile_notSpecial_returnsRate() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, null);
        Assert.areEqual(15.0, calc.computeSurcharge(null, true, false),
            'Sin productHierarchy, tile no especial → rate');
    }

    @IsTest
    static void testComputeSurcharge_noHierarchy_notTile_returnsZero() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, null);
        Assert.areEqual(0, calc.computeSurcharge('00100300010001', false, false),
            'Sin productHierarchy, no tile → 0');
    }

    @IsTest
    static void testComputeSurcharge_noHierarchy_specialTile_returnsZero() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, null);
        Assert.areEqual(0, calc.computeSurcharge('00100300010001', true, true),
            'Sin productHierarchy, tile especial → 0');
    }

    @IsTest
    static void testComputeSurcharge_blankHierarchy_tile_returnsRate() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '');
        Assert.areEqual(15.0, calc.computeSurcharge(null, true, false),
            'productHierarchy vacío, tile no especial → rate (fallback)');
    }

    /* ================================================================== */
    /* Constructor público — FIXED_BASES_002 (external object vacío)       */
    /* ================================================================== */

    @IsTest
    static void testFixedBases002_noExternalRows_rateIsZero() {
        B2BContextProvider.B2BContext ctx = new B2BContextProvider.B2BContext();
        ctx.market = new B2BContextProvider.MarketSettingsDTO();
        ctx.market.countryCode = 'IE';

        B2BPalletSurchargeCalculator calc = new B2BPalletSurchargeCalculator('FIXED_BASES_002', ctx);

        Assert.areEqual(0, calc.computeSurcharge('00100300010001', true, false),
            'FIXED_BASES_002 sin filas ZSFDesPalet__x → rate 0');
    }

    /* ================================================================== */
    /* getSurcharge — early exit y caminos de query                        */
    /* ================================================================== */

    @IsTest
    static void testGetSurcharge_rateZero_doesNotQuery() {
        B2BContextProvider.B2BContext ctx = new B2BContextProvider.B2BContext();
        B2BPalletSurchargeCalculator calc = new B2BPalletSurchargeCalculator('NOT_APPLICABLE', ctx);

        Assert.areEqual(0, calc.getSurcharge(UserInfo.getUserId()),
            'getSurcharge con rate 0 devuelve 0 sin consultar Product2');
    }

    @IsTest
    static void testGetSurcharge_productNotFound_returnsZero() {
        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');

        Id fakeProductId = '01t000000000001AAA';
        Assert.areEqual(0, calc.getSurcharge(fakeProductId),
            'Producto inexistente → 0');
    }

    @IsTest
    static void testGetSurcharge_productExists_runsComputeSurcharge() {
        Product2 prod = new Product2(Name = 'Test PSC', Umv__c = 'M2', SAPMake__c = 'P');
        insert prod;

        B2BPalletSurchargeCalculator calc = calcWithRate(15.0, '001003');
        Decimal result = calc.getSurcharge(prod.Id);

        // Jerarquia__c y fórmulas serán null sin datos SAP → 0, pero la rama queda cubierta
        Assert.areEqual(0, result,
            'Jerarquia__c nula sin datos SAP → 0, rama getSurcharge cubierta');
    }
}