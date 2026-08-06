@isTest public with sharing class B2B_UsCartToOrderControllerTest {
    
    @TestSetup static void makeData() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();
        factory.createCart();
    
    }

    @isTest private static void test_createCreditOrder() {
        WebStore store = [select Id from WebStore limit 1];
        WebCart cart = [select Id from WebCart limit 1];
        B2B_UsCartToOrderController.OrderResultDTO dto = B2B_UsCartToOrderController.createCreditOrder(store.Id, cart.Id, 'Test PO');
        Assert.isNotNull(dto, 'OrderResultDTO should not be null');
    }

    @isTest private static void test_loremIpsum() {
        String s = B2B_UsCartToOrderController.loremIpsum();
        Assert.isNotNull(s, 'Lorem ipsum should not be null');
    }
}