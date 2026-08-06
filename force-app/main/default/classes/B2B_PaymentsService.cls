@SuppressWarnings('PMD.ExcessiveParameterList')
/**
 * @author         Ramón Prades
 * @date           February 2026
 * @layer          Service
 * @description    Creates payments for B2B COmmerce
*/
public without sharing class B2B_PaymentsService {

    public static final String TYPE_CREDIT = 'CREDIT';
    public static final String TYPE_CARD = 'CARD';

    public static final String INITIAL_STATUS = 'INITIATED';
    public static final String WAITING_PAYMENT_STATUS = 'WAITING_PAYMENT';
    public static final String PAID_STATUS = 'PAID';
    public static final String COMPLETED_STATUS = 'COMPLETED';
    public static final String EXCEPTION_STATUS = 'EXCEPTION';
    public static final String FAILED_STATUS = 'FAILED';
    public static final String CANCELLED_STATUS = 'CANCELLED';

    /**
     * Creates/Updates a request for a card payment
     * This is called BEFORE redirecting to the payment gateway
     */
    public static PaymentRequest__c createCardPaymentRequest(ConnectApi.CartSummary cart, Decimal cartTotal, Decimal surcharge, Decimal surchargePct, String purchaseOrderReference) {
        
        PaymentRequest__c paymentRequest = new PaymentRequestsSelector().selectByCartId(cart.cartId);
        
        if (paymentRequest == null) {
            paymentRequest = new PaymentRequest__c();
            paymentRequest.RetryCount__c = 0;
            paymentRequest.Token__c = generatePaymentToken();
        }        
        paymentRequest.CartId__c = cart.cartId;
        paymentRequest.Account__c = cart.accountId;
        paymentRequest.Amount__c = cartTotal;
        paymentRequest.CurrencyIsoCode = cart.currencyIsoCode;
        paymentRequest.PONumber__c = purchaseOrderReference;
        paymentRequest.PaymentGateway__c = 'PORSA_GATEWAY';
        paymentRequest.PaymentMethod__c = TYPE_CARD;
        paymentRequest.StartedAt__c = System.now();
        paymentRequest.Status__c = 'WAITING_PAYMENT';
        paymentRequest.Type__c = 'PAYMENT';
        paymentRequest.User__c = UserInfo.getUserId();   
        paymentRequest.CreditCardSurcharge__c = surcharge;
        paymentRequest.CreditCardSurchargePct__c = surchargePct;     
        
        upsert paymentRequest;        

        return paymentRequest;
    }

    /**
     * Updates a payment request with the information received from the payment gateway in the callback
     */
    public static PaymentRequest__c updatePaymentFromResponse(String token, ReceivedPaymentDTO paymentInfo) {
        PaymentRequest__c paymentRequest = new PaymentRequestsSelector().selectByToken(token);
        if (paymentRequest == null) {
            throw new ObjectNotFoundException('Payment request not found for token ' + token);
        }
        Boolean ok = (paymentInfo.amount > 0);
        paymentRequest.PaidAmount__c = paymentInfo.amount;
        paymentRequest.PaidCurrency__c = paymentInfo.currencyCode;
        paymentRequest.PaidMethod__c = paymentInfo.method;
        paymentRequest.PaymentCardName__c = paymentInfo.cardName;
        paymentRequest.PaymentLast4Digits__c = paymentInfo.cardLast4Digits;
        paymentRequest.GatewayTransactionId__c = paymentInfo.transactionId;
        paymentRequest.ErrorMessage__c = paymentInfo.errorMessage;
        paymentRequest.Status__c = ok ? 'PAID' : 'FAILED';
        
        update paymentRequest;

        return paymentRequest;
    }

    /**
     * Generates a token to be used in the redirection to the payment gateway
     */
    public static String generatePaymentToken() {
        Integer bytesLength = 16;
        Blob b = Crypto.generateAesKey(bytesLength * 8); // bits
        return EncodingUtil.convertToHex(b).toLowerCase();
    }

    /* =============================================================================== */
    public class ReceivedPaymentDTO {
        public Decimal amount;
        public String currencyCode;
        public String method;
        public String cardName;
        public String cardLast4Digits;
        public String transactionId;
        public String errorMessage;
    }


}