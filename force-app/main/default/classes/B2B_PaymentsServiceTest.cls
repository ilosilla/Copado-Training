@isTest public with sharing class B2B_PaymentsServiceTest {
    @testSetup private static void testSetup() {
        DataFactoryECommerce dataFactory = new DataFactoryECommerce();
        dataFactory.buildEcommerce();  
        dataFactory.createCart();
    }
    
    @isTest private static void testCreateCardPayment() {
        WebCart cart = [select Id, WebStoreId from WebCart];
        // B2B_CommerceCartAdapter.CommerceCartData cartData = B2B_CommerceCartAdapter.getCartData(cart.WebStoreId, cart.Id);
        ConnectApi.CartSummary summary = new ConnectApi.CartSummary();
        summary.cartId = cart.Id;
        summary.accountId = [SELECT Id FROM Account LIMIT 1].Id;
        summary.currencyIsoCode = 'USD';
        Decimal cartTotal = 100;
        String poNumber = 'PO12345';
        PaymentRequest__c request = B2B_PaymentsService.createCardPaymentRequest(summary, cartTotal, 10, 2.5, poNumber);
        Assert.isNotNull(request, 'A request was expected to be created');
        Assert.isNotNull(request.Token__c, 'A token was expected to be generated');
        PaymentRequest__c request2 = B2B_PaymentsService.updatePaymentFromResponse(request.Token__c, new B2B_PaymentsService.ReceivedPaymentDTO());
        Assert.isNotNull(request2, 'A request was expected to be updated');
    }
}