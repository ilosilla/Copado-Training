@IsTest
private class UnitLabelsCommonsTest {

    @IsTest
    private static void testNormalizeUnit() {
        Assert.areEqual('BOX', UnitLabelsCommons.normalizeUnit('CJ'));
        Assert.areEqual('BOX', UnitLabelsCommons.normalizeUnit('cjs'));
        Assert.areEqual('PCS', UnitLabelsCommons.normalizeUnit('PZS'));
        Assert.areEqual('M2', UnitLabelsCommons.normalizeUnit('MT2'));
        Assert.areEqual('SQF', UnitLabelsCommons.normalizeUnit('FT2'));
        Assert.areEqual('KG', UnitLabelsCommons.normalizeUnit('kg'));
        Assert.areEqual('XYZ', UnitLabelsCommons.normalizeUnit('xyz'));
        Assert.areEqual(null, UnitLabelsCommons.normalizeUnit(null));
    }

    @IsTest
    private static void testGetUnitLabelsInEnglish() {
        UnitLabelsCommons.UnitLabelsDTO labels = UnitLabelsCommons.getUnitLabels('CJ', 'en_US');

        Assert.areEqual('BOX', labels.abbreviation);
        Assert.areEqual('Box', labels.singular);
        Assert.areEqual('Boxes', labels.plural);
        Assert.areEqual(0, labels.decimals);
    }

    @IsTest
    private static void testGetUnitLabelsInFrench() {
        UnitLabelsCommons.UnitLabelsDTO labels = UnitLabelsCommons.getUnitLabels('PZS', 'fr');

        Assert.areEqual('PCS', labels.abbreviation);
        Assert.areEqual('Pièce', labels.singular);
        Assert.areEqual('Pièces', labels.plural);
        Assert.areEqual(0, labels.decimals);
    }

    @IsTest
    private static void testGetUnitLabelsFallsBackToNormalizedCode() {
        UnitLabelsCommons.UnitLabelsDTO labels = UnitLabelsCommons.getUnitLabels('XYZ', 'en_US');

        Assert.areEqual('XYZ', labels.abbreviation);
        Assert.areEqual('XYZ', labels.singular);
        Assert.areEqual('XYZ', labels.plural);
        Assert.areEqual(2, labels.decimals);
    }

    @IsTest
    private static void testGetUnitLabelsUsesUserLanguageOverload() {
        UnitLabelsCommons.UnitLabelsDTO labelsFromOverload = UnitLabelsCommons.getUnitLabels('BOX');
        UnitLabelsCommons.UnitLabelsDTO labelsFromExplicitLanguage =
            UnitLabelsCommons.getUnitLabels('BOX', UserInfo.getLanguage());

        Assert.areEqual(labelsFromExplicitLanguage.abbreviation, labelsFromOverload.abbreviation);
        Assert.areEqual(labelsFromExplicitLanguage.singular, labelsFromOverload.singular);
        Assert.areEqual(labelsFromExplicitLanguage.plural, labelsFromOverload.plural);
    }

    @IsTest
    private static void testGetUnitLabelsThrowsWhenUnitCodeIsBlank() {
        try {
            UnitLabelsCommons.getUnitLabels('   ', 'en_US');
            Assert.fail('A ValidationException should have been thrown.');
        } catch (ValidationException ex) {
            Assert.areEqual('Unit code is required.', ex.getMessage());
        }
    }

    @IsTest
    private static void testNormalizeLanguageCode() {
        Assert.areEqual('en_US', UnitLabelsCommons.normalizeLanguageCode(null));
        Assert.areEqual('fr_CA', UnitLabelsCommons.normalizeLanguageCode('fr-CA'));
        Assert.areEqual('es', UnitLabelsCommons.normalizeLanguageCode('es'));
    }

    @IsTest
    private static void testGetDecimals() {
        Assert.areEqual(0, UnitLabelsCommons.getDecimals('CJ'));
        Assert.areEqual(0, UnitLabelsCommons.getDecimals('PZS'));
        Assert.areEqual(2, UnitLabelsCommons.getDecimals('KG'));
        Assert.areEqual(2, UnitLabelsCommons.getDecimals('MT2'));
        Assert.areEqual(2, UnitLabelsCommons.getDecimals('XYZ'));
    }

    @IsTest
    private static void testFormatQuantity() {
        Assert.areEqual('10', UnitLabelsCommons.formatQuantity(10, 'BOX'));
        Assert.areEqual('10', UnitLabelsCommons.formatQuantity(10, 'CJ'));
        Assert.areEqual('3.26', UnitLabelsCommons.formatQuantity(3.256, 'KG'));
        Assert.areEqual('7.50', UnitLabelsCommons.formatQuantity(7.5, 'M2'));
        Assert.areEqual('1.23', UnitLabelsCommons.formatQuantity(1.234, 'XYZ'));
        Assert.areEqual('', UnitLabelsCommons.formatQuantity(null, 'BOX'));
    }

    @IsTest
    private static void testGetDecimalsThrowsWhenUnitCodeIsBlank() {
        try {
            UnitLabelsCommons.getDecimals(' ');
            Assert.fail('A ValidationException should have been thrown.');
        } catch (ValidationException ex) {
            Assert.areEqual('Unit code is required.', ex.getMessage());
        }
    }

    @IsTest
    private static void testBuildLabelName() {
        Assert.areEqual('dict_uni_box_abbr', UnitLabelsCommons.buildLabelName('BOX', '_abbr'));
        Assert.areEqual('dict_uni_pcs_one', UnitLabelsCommons.buildLabelName('PCS', '_one'));
        Assert.areEqual('dict_uni_sqf_many', UnitLabelsCommons.buildLabelName('SQF', '_many'));
    }
}