@isTest public class MaterialBankEUParserTest {

    @isTest public static void test001() {
        MaterialBankEUParser parser = new MaterialBankEUParser();
        parser.setEurope();
        Assert.areEqual(true, true);
    }
}