/**
 * @author         Ramón Prades
 * @date           January 2026
 * @layer          Controllers
 * @description    Controller class for the cartToOrder component
*/
public without sharing class B2B_UsCartToOrderController {
  
    @AuraEnabled
    public static OrderResultDTO createCreditOrder(Id webstoreId, Id cartId, String purchaseOrderReference) {
        OrderResultDTO resultDTO = new OrderResultDTO();
        try {
            Order o = B2B_CommerceOrdersService.createCreditOrder(webstoreId, cartId, purchaseOrderReference);
            Order newOrder = (Order) new OrdersSelector().selectSingle(o.Id);
            resultDTO.success = true;
            resultDTO.orderNumber = newOrder.OrderNumber;
            resultDTO.errorMessage = '';
        } catch (Exception ex) {
            resultDTO.success = false;
            resultDTO.errorMessage = ex.getMessage();
        }

        //ConnectApi.CommerceCart.deleteCart(webstoreId, null, cartId);
        /*
        WebCart cart = new WebCart();
        cart.Id = cartId;
        cart.WebStoreId = webstoreId;
        cart.PoNumber = 'PO/APEX/001';
        cart.Status = 'Closed';
        update cart;
        
        resultDTO.errorMessage = 'Pasar ha pasado';
        */
        return resultDTO;
    }

    /**
     * This method prepares the redirection to the card payment gateway. 
     * It doesn't create the order yet, as the order creation will be triggered asynchronously 
     * when the payment gateway calls back to our B2B_PaymentGatewayCapture endpoint with the payment result.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static RedirectPayloadDTO prepareCardPaymentRedirect(Id webstoreId, Id cartId, String purchaseOrderReference, Decimal cardSurcharge, Decimal cardSurchargePct, Decimal cartTotal) {

        B2B_CommerceCartAdapter.CommerceCartData cartData = readCart(webstoreId, cartId);
        PaymentRequest__c paymentRequest = B2B_PaymentsService.createCardPaymentRequest(cartData.cart, cartTotal, cardSurcharge, cardSurchargePct, purchaseOrderReference);

        // Create the payload for the payment gateway
        B2B_PaymentGatewayRedirectHelper helper = new B2B_PaymentGatewayRedirectHelper(cartData);
        helper.setUniqueId(paymentRequest.Id);
        helper.setCartTotal(cartTotal);
        helper.setCardSurcharge(cardSurcharge);
        helper.setPoNumber(purchaseOrderReference);
        helper.setToken(paymentRequest.Token__c);

        RedirectPayloadDTO payload = new RedirectPayloadDTO();
        payload.fields = helper.getFieldsPayload();
        payload.redirectUrl = helper.getRedirectURL();

        return payload;    
    }

    @AuraEnabled public static PaymentResponseDTO getPaymentRequestStatus(String token) {        
        PaymentRequestsSelector selector = new PaymentRequestsSelector();
        PaymentRequest__c request = selector.selectByToken(token);
        if (request == null) {
            throw new AuraHandledException('Payment request not found');
        }
        String orderNumber = '';
        if (request.Order__c != null) {
            Order[] orders = [SELECT OrderNumber FROM Order WHERE Id = :request.Order__c];
            if (orders.size() > 0) {
                orderNumber = orders[0].OrderNumber;
            }
        }
        PaymentResponseDTO dto = new PaymentResponseDTO();
        dto.orderNumber = orderNumber;
        dto.status = request.Status__c;
        return dto;
    }

    /* ==================================================================== */

    /*
     * Reads the cart using the ConnectApi
     */
    private static B2B_CommerceCartAdapter.CommerceCartData readCart(Id webstoreId, Id cartId) {
        B2B_CommerceCartAdapter.CommerceCartData cartData = B2B_CommerceCartAdapter.getCartData(webstoreId, cartId);
        if (cartData == null || cartData.cart == null) {
            throw new ObjectNotFoundException('Cart not found or empty.');
        }
        if (cartData.cart.status != ConnectApi.CartStatus.CHECKOUT) {
            throw new ContextException('Cart is not in checkout status. Current status: ' + cartData.cart.status);
        }
        return cartData;
    }

    public class RedirectPayloadDTO {
        @AuraEnabled public String redirectUrl;
        @AuraEnabled public Map<String, String> fields;
    }

    public class OrderResultDTO {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String errorMessage;
        @AUraEnabled public String raw;
    }

    public class PaymentResponseDTO {
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String message; 
    }

    /**
     * Lorem Ipsum method for testing purposes
     */
    @testVisible private static String loremIpsum() {
        String lorem = 'Lorem ipsum dolor sit amet, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ';
        lorem += 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ';    
        return lorem;
    }
}