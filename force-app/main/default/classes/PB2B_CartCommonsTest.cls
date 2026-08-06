@isTest public with sharing class PB2B_CartCommonsTest {

    @testSetup private static void testSetup() {                    
    }

    @isTest private static void testAll() {
        //CartExtension.CartValidationOutputList outputList = new CartExtension.CartValidationOutputList();
        CartExtension.CartValidationOutputTypeEnum outputType = CartExtension.CartValidationOutputTypeEnum.SHIPPING;
        try {
            PB2B_CartCommons.clearValidations(null, outputType);
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage());
        }

        try {
            PB2B_CartCommons.clearTaxValidations(null);
        }  catch (Exception e) {
            Assert.isNotNull(e.getMessage());
        }

        try {
            PB2B_CartCommons.clearShippingValidations(null);
        }  catch (Exception e) {
            Assert.isNotNull(e.getMessage());
        }
            
        //String s = PB2B_CartCommons.testLorem();
        //Assert.isNotNull(s);
    }

    @IsTest
    static void testGetCartWeightKg() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();
        WebCart cart = factory.createCart();
        Decimal expected = 0;
        CartItem[] items = [select Id, Product2.Id, Quantity, PerUnitWeight from CartItem where CartId = :cart.Id];
        for (CartItem item : items) {
            item.PerUnitWeight = 100;
            expected += (item.PerUnitWeight * item.Quantity);
        }
        update items;   

        Test.startTest();
        Decimal weight = PB2B_CartCommons.getCartWeightKg(cart.Id);
        Test.stopTest();
        Assert.areNotEqual(0, expected, 'Expected weight should be non zero');
        Assert.areEqual(expected, weight, 'El peso debería ser ' + expected);
    }

}