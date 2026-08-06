/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_ConfirmPrice
     Created Date:      16/02/2022
     Author:            Ignacio G. Schuhmacher
     Mail:              ignacio.galindo@nubika.com
     Description:       Pricing confirmation not necessary yet
------------------------------------------------------------------------------------------*/
public class NB2B_ActivateOrder {

    public class ActivateOrder {
        
        @InvocableVariable(required=true)
        public ID checkoutSessionId;
        
        @InvocableVariable(required=true)
        public ID cartId;
    }
    
    /**
     * @description Maps a cart to an order. Activates it, and closes the cart. Returns the resulting order summary id.
     * @param request The checkout session and cart id.
     * @return The OrderId that resulted from this class.
     */
    @InvocableMethod(label='Activate Order' description='Close the cart and activate order' category='B2B Commerce')
    public static void cartToOrder(List<ActivateOrder> request) {
        System.debug('NB2B_ActivateOrder cartToOrder start');
        // screen flows do not run in bulk
        Id cartId = request[0].cartId;
        Id checkoutSessionId = request[0].checkoutSessionId;
        List<Order> orderList = new List<Order>();
        Savepoint sp;
        try{
            
            List<WebCart> carts = [SELECT Id,
                               PoNumber
                               FROM WebCart WHERE Id = :cartId];
        	WebCart cart = carts[0];
            
			orderList = [Select id,
                         	PoNumber,
                         	Status
                        	From Order
                        	where PoNumber =: cart.PoNumber
                         	And Status != 'Activated'
                        	Order by CreatedDate DESC
                        	Limit 1];
            cart.Status = 'Closed';
            System.debug('OrderList : ' + orderList);
            if(!orderList.isEmpty()){
                Order order = orderList[0];
                order.Status = 'Activated';
                if(!Test.isRunningTest()){
                    //sendOrder(order);
                    sp = Database.setSavepoint();
                    
                }
                update order;
                if(!Test.isRunningTest()){
                	updateCheckoutSession(checkoutSessionId, order.Id);
                }
                
            }else{
				System.debug('NB2B_ActivateOrder cartToOrder Empty Order list');
            }
            
        }catch(Exception e){
            System.debug('NB2B_ActivateOrder cartToOrder exception : ' + e);
            if(sp != null){
                Database.rollback(sp);
            }
        }
        return;
    }
    /**
     * @description Satisfy the preconditions required to use the following call to Activate the Order
     */
    /*private static void sendOrder(Order thisOrder) {
        String sapId;
        try {
           	NB2B_OrderTransactionHandler.TransactionResponse response = NB2B_OrderController.saveOrder(thisOrder.Id);
            if(response.success == Nb2b_GlobalConstants.TRUE_STRING){
                sapId = response.OrderNumber;
                if(sapId.startsWith('00')){
                    sapId = sapId.right(sapId.length()-2);
                }
                thisOrder.Sap_Id__c  = sapId;
            }
        } catch (Exception e) {
            System.debug('An error occurred updating checkout session with the draft order Id');
            return;
        }
    }*/
    /**
     * @description Satisfy the preconditions required to use the following call to Activate the Order
     */
    private static void updateCheckoutSession(Id checkoutSessionId, Id orderId) {
        try {
            CartCheckoutSession checkoutSession = [SELECT OrderId, State, NextState FROM CartCheckoutSession WHERE Id = :checkoutSessionId LIMIT 1];
            checkoutSession.OrderId = orderId;
            checkoutSession.State = checkoutSession.NextState;
            update checkoutSession;
        } catch (Exception e) {
            System.debug('An error occurred updating checkout session with the draft order Id');
        }
    }
}