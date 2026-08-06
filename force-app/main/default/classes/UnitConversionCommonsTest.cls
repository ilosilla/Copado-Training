@isTest public class UnitConversionCommonsTest {

    @isTest private static void testBooleanMethods() {
        String unit = 'M2';
        Assert.isTrue(UnitConversionCommons.isValid(unit));
        Assert.isTrue(UnitConversionCommons.isSquareMetre(unit));
        Assert.isFalse(UnitConversionCommons.isBox(unit));
        Assert.isFalse(UnitConversionCommons.isPiece(unit));
    }

    @isTest private static void testConversionMethods() {
        UnitConversionCommons.Factors f = new UnitConversionCommons.Factors();
        f.PcsXBox = 4;
        f.M2XBox = 1.2;

        Assert.areEqual(40, UnitConversionCommons.ConvertFromTo(10, 'BOX', 'PCS', f));
        Assert.areEqual(12, UnitConversionCommons.ConvertFromTo(10, 'BOX', 'M2', f));

        Assert.areEqual(2.5, UnitConversionCommons.ConvertFromTo(10, 'PCS', 'BOX', f));
        Assert.areEqual(12, UnitConversionCommons.ConvertFromTo(40, 'PCS', 'M2', f));

        Assert.areEqual(2, UnitConversionCommons.ConvertFromTo(2.4, 'M2', 'BOX', f));
        Assert.areEqual(8, UnitConversionCommons.ConvertFromTo(2.4, 'M2', 'PCS', f));

        Assert.areEqual(26, UnitConversionCommons.ConvertFromTo(2.4, 'M2', 'FT2', f).setScale(0, RoundingMode.CEILING));
        Assert.areEqual(0.93, UnitConversionCommons.ConvertFromTo(10, 'FT2', 'M2', f).setScale(2, RoundingMode.CEILING));

        Decimal weightPerM2 = 2.4;
        Decimal weightPerBox = f.M2XBox * weightPerM2;
        Assert.areEqual(weightPerBox, UnitConversionCommons.ConvertWeightFromTo(weightPerM2, 'M2', 'BOX', f));

    }
}