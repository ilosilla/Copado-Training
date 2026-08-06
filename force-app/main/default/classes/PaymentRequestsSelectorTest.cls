@isTest public class PaymentRequestsSelectorTest {
    
    @isTest private static void testSelectByCartId() {
        // Test selector
        Id fakeId = '001000000000001'; 
        PaymentRequestsSelector selector = new PaymentRequestsSelector();
        PaymentRequest__c result = selector.selectByCartId(fakeId);
        Assert.isNull(result, 'Expected no payment request for a non-existing cart ID');
    }

    @isTest private static void testSelectByToken() {
        // Test selector
        String token = 'A1A1A1A1A1A1A1A1A1A1A1A1A1'; 
        PaymentRequestsSelector selector = new PaymentRequestsSelector();
        PaymentRequest__c result = selector.selectByToken(token);
        Assert.isNull(result, 'Expected no payment request for a non-existing token');
    }
}