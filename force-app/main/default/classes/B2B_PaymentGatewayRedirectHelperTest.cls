@isTest public with sharing class B2B_PaymentGatewayRedirectHelperTest {

    @isTest(SeeAllData=true) static void testRedirectHelper() {
        // --- Setup ---
        DataFactoryEcommerce factory = new DataFactoryEcommerce();
        factory.buildEcommerce();    
        WebCart cart = factory.createCart();
        cart.Status = 'Checkout';
        update cart;
        Account acc = new Account();
        acc.Id = cart.AccountId;
        acc.BillingStreet = '7 Boroline Road';
        acc.BillingCity = 'Hackensack';
        acc.BillingPostalCode = '07700';
        acc.BillingCountryCode = 'US';
        acc.BillingCountry = 'United States';
        acc.BillingStateCode = 'NJ';
        update acc; 

        PORSAStoreSettings__c storeSettings = PORSAStoreSettings__c.getInstance('US_DEALERS');
        if (storeSettings == null) {
            storeSettings = new PORSAStoreSettings__c();
            storeSettings.Name = 'US_DEALERS';
            storeSettings.Secret__c = 'C8CnCpx4kFuxBofxUJFqnS26L2XXXX';
            storeSettings.RedirectTo__c = 'https://porsa.dummy.com/sforce-rpr/openapi/v2/payment-gateway-response/';
            storeSettings.MerchantID__c = '123456789';
            storeSettings.CaptureURL__c = 'https://porsa.dummy.com/sforce-rpr/openapi/v2/payment-gateway-capture/';
            storeSettings.PaymentGatewayURL__c = 'https://porsa.dummy.com/payment-gateway/redirect';
            insert storeSettings;
        }
              
        Test.startTest();
        B2B_CommerceCartAdapter.CommerceCartData cartData = B2B_CommerceCartAdapter.getCartData(factory.StoreId, cart.Id);
        B2B_PaymentGatewayRedirectHelper helper = new B2B_PaymentGatewayRedirectHelper(cartData);
        helper.setCardSurcharge(10);
        helper.setCartTotal(100);
        helper.setUniqueId('unique-123');
        helper.setPoNumber('PO-456');
        helper.setToken('token-789');  
        Map<String, String> fields = helper.getFieldsPayload();
        Test.stopTest();
        Assert.isNotNull(fields, 'Fields payload should not be null');
    }
}