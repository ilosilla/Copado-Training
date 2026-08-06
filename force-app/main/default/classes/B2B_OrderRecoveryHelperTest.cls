@isTest
private class B2B_OrderRecoveryHelperTest {

    @TestSetup
    static void makeData(){
        DataFactoryAccount.createAccounts(1);
    }

    @isTest
    static void save_createsRecoveryRecord() {
        Account acc = [select Id from Account limit 1];
        String runId = '001';
        String cartId = 'cart-' + runId;
        String storeId = 'store-' + runId;
        String errorMessage = 'Order creation failed for run ' + runId;
        String cartJson = '{"cartId":"' + runId + '"}';
        String paymentJson = '{"status":"CAPTURED"}';
        String auxJson = '{"source":"test"}';

        Test.startTest();
        new B2B_OrderRecoveryHelper()
            .withAccountId(acc.Id)
            .withCartId(cartId)
            .withCartJson(cartJson)
            .withPaymentJson(paymentJson)
            .withAuxJson(auxJson)
            .withStoreId(storeId)
            .withErrorMessage(errorMessage)
            .save();
        Test.stopTest();

        B2B_OrderRecovery__c saved = [
            SELECT AccountId__c, CartId__c, CartJSON__c, PaymentJSON__c, AuxJSON__c, StoreId__c, ErrorMessage__c
            FROM B2B_OrderRecovery__c            
            LIMIT 1
        ];

        System.assertEquals(acc.Id, saved.AccountId__c, 'Account id should be saved');
        System.assertEquals(cartId, saved.CartId__c, 'Cart id should be saved');
        System.assertEquals(cartJson, saved.CartJSON__c, 'Cart JSON should be saved');
        System.assertEquals(paymentJson, saved.PaymentJSON__c, 'Payment JSON should be saved');
        System.assertEquals(auxJson, saved.AuxJSON__c, 'Aux JSON should be saved');
        System.assertEquals(storeId, saved.StoreId__c, 'Store id should be saved');
        System.assertEquals(errorMessage, saved.ErrorMessage__c, 'Error message should be saved');
    }
}