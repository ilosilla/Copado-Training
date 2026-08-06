/**
 * This is designed as a handy starting point for writing code to convert a cart to an order. The built in CartToOrder invocable
 * action is maintained and has additions and fixes not found in this class. Whenever possible, it is suggested to use that invocable
 * action rather than relying on this invocable action that has limited support and is not tested each release.
 *
 * Multi-currency has not been tested, though you'll see a couple uses of currency codes (CurrencyIsoCode) commented out in this class.
 * If you are using multi-currency in your org, I would uncomment those lines out.
 *
 * @description CartToOrder Flow Invocation process.
 * @author Nubika Team
 */
@SuppressWarnings('PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity, PMD.ApexSharingViolations')
public class NB2B_CartToOrderManager {

    /**
     * @description Flow Input Wrapper class.
     * @author Nubika Team
     * /
    public class B2BCartToOrderInput {

        @InvocableVariable(required=true)
        public ID checkoutSessionId;

        @InvocableVariable(required=true)
        public ID cartId;
    }
    // FROM HERE ---------__>
    /**
     * @description Flow Output Wrapper class.
     * @author Nubika Team
     */
    public class B2BCartToOrderOutput {
        @InvocableVariable(required=true)
        public String errorTxt;

        @InvocableVariable(required=true)
        public ID orderId;

        @InvocableVariable(required=true)
        public Boolean showError;

        @InvocableVariable(required=true)
        public String displayType = 'error';

        @InvocableVariable(required=true)
        public Boolean deleteCart;

        @InvocableVariable(required=true)
        public Boolean isOrderOk;

        /**
         * Default Constructor
         */
        public B2BCartToOrderOutput(){} //NOPMD

         /**
         * @description Constructor
         * @param errorTxt - errorMessage
         * @param orderId - resultant Order Record Id
         * @param showError - true/false -> indicates if error should be displayed to user.
         * @param deleteCart - true/false -> abort operation
         * @param isOrderOk - true/false -> indicates if Order generation is OK.
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public B2BCartToOrderOutput(String errorTxt, ID orderId, Boolean showError, Boolean deleteCart, Boolean isOrderOk) {
            this.errorTxt = errorTxt;
            this.orderId = orderId;
            this.showError = showError;
            this.deleteCart = deleteCart;
            this.isOrderOk = isOrderOk;
        }
    }
    // -----> TO HERE

    /**
     * @description Maps a cart to an order. Activates it, and closes the cart. Returns the resulting order summary id.
     * @param lInputs The checkout session and cart id.
     * @return The OrderId that resulted from this class.
     * /
    @InvocableMethod(label='Map Cart to Order' description='Maps the cart and related data to an order' category='B2B Commerce')
    public static List<B2BCartToOrderOutput> cartToOrder(List<B2BCartToOrderInput> lInputs) {
        List<B2BCartToOrderOutput> lOutputs = new List<B2BCartToOrderOutput>();
        Savepoint sp;
        try{
            B2BCartToOrderInput request = lInputs.get(0);

            //RETRIEVE: WEBCART
            List<WebCart> lCarts = [
                SELECT Id,
                    AccountId,
                    OwnerId,
                    WebStoreId,
                    WebStore.Name,
                    PoNumber,
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    BillingCountry,
                    BillingLatitude,
                    BillingLongitude,
                    CurrencyIsoCode,
                    TotalListAmount,
                    TotalProductCount,
                    TotalAmount,
                    Owner.email
                FROM WebCart 
                WHERE Id = :request.cartId
                LIMIT 1
            ];
            //TODO: Convertir mensaje display en label
            if(lCarts.isEmpty()){ throw new CartToOrderException('ERROR[CartToOrder]: Not Found WebCart for this CartId "' + request.cartId +'"').setDisplayMessage(Label.NB2B_CartToOrder_NoWebcart); }
            WebCart cart = lCarts.get(0);


            //RETRIEVE: CART DELIVERY GROUP FOR CART
            List<CartDeliveryGroup> lCartDeliveryGroups = [
                SELECT
                    DesiredDeliveryDate,
                    DeliverToName,
                    ShippingInstructions,
                    DeliverToStreet,
                    DeliverToCity,
                    DeliverToState,
                    DeliverToPostalCode,
                    DeliverToCountry,
                    DeliverToLatitude,
                    DeliverToLongitude,
                    DeliveryMethodId,
                    DeliveryMethod__c,
                    SalesOrg__c,
                    ContactPointAddressId__c,
                    ContactPointAddressId__r.SAPId__c
                FROM CartDeliveryGroup 
                WHERE CartId = :request.cartId
                LIMIT 1
            ];

            if(lCartDeliveryGroups.isEmpty()){ throw new CartToOrderException('ERROR[CartToOrder]: Not Found CartDeliveryGroups for this CartId "' + request.cartId +'"').setDisplayMessage(Label.NB2B_CartToOrder_NoDeliveryGroup); }
            CartDeliveryGroup cartDeliveryGroup = lCartDeliveryGroups.get(0);
            
            List<CartItem> lCartItems = [
                SELECT
                    AdjustmentAmount,
                    Product2Id,
                    Product2.UmbKg__c,
                    Type,
                    Quantity,
                    ListPrice,
                    SalesPrice,
                    TotalLineAmount,
                    TotalAmount,
                    NB2B_Shade__c,
                    Cart.WebStore.Name,
                    NB2B_SalesOrg__c
                FROM CartItem 
                WHERE cartId = :request.cartId
            ];
            if(lCartItems.isEmpty()){ throw new CartToOrderException('ERROR[CartToOrder]: cart is empty').setDisplayMessage(System.Label.NB2B_CartOrderEmptyError); }
            
            //RETRIEVE: SAP ACCOUNT AND ID
            List<User> lUsers = [
                SELECT
                    Id,
                    Contact.Account.Sap_Id__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                    AND Contact.Account.Sap_Id__c != null
                LIMIT 1
            ];
            //TODO: Cambiar label de error.
            if(lUsers.isEmpty()){ throw new CartToOrderException('ERROR[CartToOrder]: not Found SAP ID Account').setDisplayMessage(System.Label.NB2B_CartOrderEmptyError); } 


            //BUILD: ORDER DATA
            OrderData data = new OrderData(cart,cartDeliveryGroup,lCartItems).build();

            //RETRIEVE: ORDER ITEMS RELATED PRODUCTS DATA
            Map<Id,Product2> mProductsById = new Map<Id,Product2>([
                SELECT
                    Id,
                    Name,
                    StockKeepingUnit,
                    NB2B_Sales_Unit__c,
                    Umv__c
                FROM Product2
                WHERE Id IN :data.sProductIds
            ]);

            //GENERATING ORDER INTO SAP SYSTEM
            NB2B_OrderTransactionHandler.Response response = NB2B_OrderController.saveOrder(data.order, data.lOrderItems, mProductsById, lUsers.get(0).Contact.Account.Sap_Id__c);

            B2BCartToOrderOutput output = null; // response.generateFlowOutput();
            lOutputs.add(output);
            if(response.isBlockOrder()){
                return lOutputs;
            }

            //INSERT ORDER WITH SYNCHED SAP ID
            sp = Database.setSavepoint();
            String orderNumber = response?.OrderNumber;
            data.order.SAP_Id__c = String.isNotBlank(orderNumber) && orderNumber.startsWith('00')? orderNumber.right(orderNumber.length()-2) : orderNumber;
            
            insert data.order;

            //INSERT ORDER DELIVERY GROUP FOR CREATED ORDER
            data.orderDeliveryGroup.OrderId = data.order.Id;
            insert data.orderDeliveryGroup;

            //INSERT ORDER ITEMS
            for(OrderItem oI : data.lOrderItems){
                oI.OrderId = data.order.Id;
                oI.OrderDeliveryGroupId = data.orderDeliveryGroup.Id;
            }
            insert data.lOrderItems;

            //UPDATING CHECKOUT SESSION WITH NEW CREATED ORDER
            if(!Test.isRunningTest()){  updateCheckoutSession(request.checkoutSessionId, data.order.Id); }

            if(String.isBlank(data.order.SAP_Id__c)){
                createError('[NB2B_CartToOrder] - Generated Order with Id "' + data.order.Id + '" without SAPId. Server Response detail: ' + response,new Set<String>{'NB2B_CartToOrder',NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG,Nb2b_GlobalConstants.LOGGER_B2B_SEND_EMAIL});
            }

            //UPDATE SUCCESS OUTPUT
            output.orderId = data.order.Id;
            output.isOrderOK = true;
        }
        catch(DMLException e){
            Database.rollback(sp);
            throw new CartToOrderException('[NB2B_CartToOrder] - [SAVE ERROR]: ' + e.getMessage() + '\n' + e.getStackTraceString()).setDisplayMessage(System.Label.NB2B_CartOrderSaveError);
        }
        catch(CartToOrderException e){ return createError(e); }
        catch(Exception e) { return createError('[NB2B_CartToOrder] - [UNKNOWN ERROR]: ' + e.getMessage() + '\n' + e.getStackTraceString(),System.Label.NB2B_CartUnknownError,new Set<String>{'NB2B_CartToOrder'}); }
        return lOutputs;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void updateCheckoutSession(Id checkoutSessionId, Id orderId) {
        try {
            List<CartCheckoutSession> lCheckoutSessions = [
                SELECT
                    OrderId,
                    State,
                    NextState
                FROM CartCheckoutSession
                WHERE Id = :checkoutSessionId
                LIMIT 1
            ];
            if(lCheckoutSessions.isEmpty()){ throw new CartToOrderException('ERROR [CartToOrder]: not found checkoutSession with Id "' + checkoutSessionId + '"').setDisplayMessage(Label.NB2B_CartToOrder_CheckoutSessionError); }
            CartCheckoutSession checkoutSession = lCheckoutSessions.get(0);
            checkoutSession.OrderId = orderId;
            checkoutSession.State = checkoutSession.NextState;
            update checkoutSession;
        }
        catch(CartToOrderException e){ throw e;}
        catch (Exception e) {
            throw new CartToOrderException('ERROR [CartToOrder]: An error occurred updating checkout session with Id "' + checkoutSessionId + '" for the draft order Id "' + orderId + '" - ' + e.getMessage() + '\n' + e.getStackTraceString()).setDisplayMessage(Label.NB2B_CartToOrder_CheckoutSessionError);
        }
    }

    @SuppressWarnings('PMD.ApexSharingViolations')
    private class OrderData{
        //Inputs
        private WebCart cart;
        private CartDeliveryGroup cartDeliveryGroup;
        private List<CartItem> lCartItems;

        //Outputs
        private Order order;
        private OrderDeliveryGroup orderDeliveryGroup;
        private List<OrderItem> lOrderItems = new List<OrderItem>();
        private Set<Id> sProductIds = new Set<Id>();

        /**
         * @description Constructor
         * @param  cart - WebCart in context
         * @param cartDeliveryGroup - CartDeliveryGroup in context
         * @param lCartItems - CartItems in context
         * /
        public OrderData(WebCart cart, CartDeliveryGroup cartDeliveryGroup, List<CartItem> lCartItems){
            this.cart = cart;
            this.cartDeliveryGroup = cartDeliveryGroup;
            this.lCartItems = (lCartItems != null)? lCartItems : new List<CartItem>();
        }

        /**
         * @description Method for build the wrapper
         * @return self instance built
         * /
        public OrderData build(){
            buildOrderData();
            buildOrderDeliveryGroupData();
            buildDataFromItems();
            return this;
        }

        @SuppressWarnings('PMD.ApexCRUDViolation')
        private void buildOrderData(){
            //CALCULATE: deliveryCode
            String deliveryCode = cartDeliveryGroup.ContactPointAddressId__r?.SapId__c;
            //deliveryCode = (String.isBlank(deliveryCode))? cartDeliveryGroup.NB2B_Porcelanosa_Address__r?.NBK_SAPId__c : deliveryCode;
            if(String.isBlank(deliveryCode)){
                List<Account> lAccounts = [
                    SELECT Id, Sap_Id__c
                    FROM Account
                    WHERE Id = :cart.AccountId
                    LIMIT 1
                ];

                deliveryCode = (!lAccounts.isEmpty())? lAccounts.get(0).Sap_Id__c : null;
            }

            if(String.isBlank(deliveryCode)){ throw new CartToOrderException('[ERROR]: deliveryCode is null').setDisplayMessage(Label.NB2B_CartToOrder_NoDeliveryCode); }

            //RETRIEVE: COUNTRY TAX RATE
            List<NB2B_CountryTaxes__mdt> lTaxes = [
                SELECT Id, NB2B_Country__c, NB2B_Taxes__c, NB2B_TaxName__c
                FROM NB2B_CountryTaxes__mdt
                where NB2B_Country__c =: cart.WebStore.Name
            ];

            //CALCULATE: Company
            String company;

            //BUILD: Order
            Date nowDate = Date.today();
            this.order = new Order(
                RecordTypeId                    = Schema.SObjectType.Order.getRecordTypeInfosByName().get('B2B').getRecordTypeId(),
                AccountId 				        = cart.AccountId,
                OwnerId 				        = cart.OwnerId,
                SalesStoreId 			        = cart.WebStoreId,
                PoNumber 				        = cart.PoNumber,
                BillingStreet 			        = cartDeliveryGroup.DeliverToStreet,
                BillingCity 			        = cartDeliveryGroup.DeliverToCity,
                BillingState 			        = cartDeliveryGroup.DeliverToState,
                BillingPostalCode 		        = cartDeliveryGroup.DeliverToPostalCode,
                BillingCountry 			        = cartDeliveryGroup.DeliverToCountry,
                BillingLatitude 		        = cartDeliveryGroup.DeliverToLatitude,
                BillingLongitude 		        = cartDeliveryGroup.DeliverToLongitude,
                ShippingStreet 			        = cartDeliveryGroup.DeliverToStreet,
                ShippingCity 			        = cartDeliveryGroup.DeliverToCity,
                ShippingState 			        = cartDeliveryGroup.DeliverToState,
                ShippingPostalCode 		        = cartDeliveryGroup.DeliverToPostalCode,
                ShippingCountry 		        = cartDeliveryGroup.DeliverToCountry,
                ShippingLatitude 		        = cartDeliveryGroup.DeliverToLatitude,
                ShippingLongitude 		        = cartDeliveryGroup.DeliverToLongitude,
                Status 					        = Nb2b_GlobalConstants.ORDER_STATUS_DRAFT,
                DeliveryDate__c 		        = cartDeliveryGroup.DesiredDeliveryDate?.date(),
                NB2b_store_pickup__c  	        = (cartDeliveryGroup.DeliveryMethod__c == 'CUSTOMER-PICKUP'),
                Company__c				        = company,
                Currency__c				        = cart.CurrencyIsoCode,
                CurrencyIsoCode			        = cart.CurrencyIsoCode,
                NB2B_NetAmmount__c		        = cart.TotalAmount,
                Quantity__c				        = cart.TotalProductCount,
                Observations__c			        = cartDeliveryGroup.ShippingInstructions,
                Unit__c 				        = cart.CurrencyIsoCode,
                Origin__c 				        = Nb2b_GlobalConstants.ORDER_ORIGIN_B2B,
                TaxRate__c				        = (!lTaxes.isEmpty())? lTaxes.get(0).NB2B_Taxes__c : null,
                Firm__c					        = false,
                NB2B_OrderCode__c               = '',
                NB2B_DeliveryCode__c            = deliveryCode,
                BillingEmailAddress		        = cart.Owner.email,
                EffectiveDate 			        = nowDate,
                OrderedDate 			        = nowDate,
                NB2B_Oreder_Created_Date__c     = nowDate
            );
        }

        private void buildOrderDeliveryGroupData(){
            // Create the order delivery group
            this.orderDeliveryGroup = new OrderDeliveryGroup(
                DesiredDeliveryDate     = cartDeliveryGroup.DesiredDeliveryDate?.date(),
                DeliverToName           = cartDeliveryGroup.DeliverToName,
                DeliveryInstructions    = cartDeliveryGroup.ShippingInstructions,
                DeliverToStreet         = cartDeliveryGroup.DeliverToStreet,
                DeliverToCity           = cartDeliveryGroup.DeliverToCity,
                DeliverToState          = cartDeliveryGroup.DeliverToState,
                DeliverToPostalCode     = cartDeliveryGroup.DeliverToPostalCode,
                DeliverToCountry        = cartDeliveryGroup.DeliverToCountry,
                DeliverToLatitude       = cartDeliveryGroup.DeliverToLatitude,
                DeliverToLongitude      = cartDeliveryGroup.DeliverToLongitude,
                OrderDeliveryMethodId   = cartDeliveryGroup.DeliveryMethodId
            );
        }

        @SuppressWarnings('PMD.ApexCRUDViolation')
        private void buildDataFromItems(){
            //CALCULATE: TAX AMOUNT
            order.Tax__c = 0;
            order.Amount__c = 0;
            Map<Id,CartTax> mCartTaxByItemId = new Map<Id,CartTax>();
            for(CartTax cTax : [
                SELECT Id, CartItemId, Amount
                FROM CartTax
                WHERE cartId = :cart.Id
            ]){
                mCartTaxByItemId.put(cTax.CartItemId, cTax);
                order.Tax__c += (cTax.Amount != null)? cTax.Amount : 0;
            }

            //CALCULATE: weight, amount and Generate Order Items.
            Decimal weight = 0;
            String salesOrgStr;
            order.Amount__c = order.Tax__c;
            for(CartItem cItem: lCartItems){
                Decimal itemTaxAmount = mCartTaxByItemId.get(cItem.Id)?.Amount;
                itemTaxAmount = (itemTaxAmount != null)? itemTaxAmount : 0;
                weight += ((cItem.Product2.UmbKg__c != null)? cItem.Product2.UmbKg__c : 0) * ((cItem.Quantity != null)? cItem.Quantity : 1);
                order.Amount__c += cItem.TotalLineAmount;
                salesOrgStr = (String.isBlank(salesOrgStr))? cItem.NB2B_SalesOrg__c : salesOrgStr;

                sProductIds.add(cItem.Product2Id);
                lOrderItems.add(new OrderItem(
                    Product2Id              = cItem.Product2Id,
                    Type                    = Nb2b_GlobalConstants.ORDER_ITEM_TYPES.get(cItem.Type),
                    Quantity                = cItem.Quantity,
                    ListPrice               = cItem.TotalLineAmount + itemTaxAmount,
                    GrossUnitPrice          = cItem.ListPrice,
                    UnitPrice               = (cItem.SalesPrice != null)? cItem.SalesPrice : cItem.ListPrice,
                    TotalLineAmount         = cItem.TotalLineAmount,
                    NB2B_Position__c        = lOrderItems.size()+1,
                    NB2B_TaxAmount__c       = itemTaxAmount,
                    NB2B_Shade__c           = cItem.NB2B_Shade__c
                ));
            }
            order.Total_Weight__c = String.valueOf(weight);

            //CALCULATE: Sales Org, Sales Office, Distribution Channel
            order.SalesOrg__c = Nb2b_GlobalConstants.ORDER_DEFAULT_SALES_ORG;
            order.SalesOffice__c = Nb2b_GlobalConstants.ORDER_DEFAULT_SALES_OFFICE;
            if(String.isBlank(salesOrgStr)){
                User ownerUser = [Select Id, Contact.SAP_Accounting_Info__c From User Where Id = :cart.OwnerId];
                salesOrgStr = ownerUser.Contact.SAP_Accounting_Info__c;
            }

            if(String.isNotBlank(salesOrgStr)){
                List<Sales_Relationship__c> lSalesRels = [
                    SELECT Id, Name, CurrencyIsoCode,
                        Account_Org__c, Business_Unit__c,
                        Commercial__c, Commission_Agent__c,
                        Currency__c, Custom_Id__c,
                        Distribution_Channel__c,
                        Email__c, Notes__c,
                        Phone__c, Relationship__c,
                        SAP_Id__c, Sales_Office__c,
                        Sales_Org__c, Error_Message__c,
                        Reason_of_creation__c, Sap_Status__c
                    FROM Sales_Relationship__c
                    WHERE Account_Org__c =:cart.AccountId
                        AND Id =:salesOrgStr
                    LIMIT 1
                ];

                if(!lSalesRels.isEmpty()){
                    Sales_Relationship__c sales = lSalesRels.get(0);
                    order.SalesOrg__c 	            = sales.Sales_Org__c;
                    order.SalesOffice__c            = sales.Sales_Office__c;
                    order.Distribution_channel__c   = sales.Distribution_Channel__c;
                }
            }
        }
    }

    @TestVisible
    private static List<B2BCartToOrderOutput> createError(String errorMsg, String displayErrorMessage, Set<String> sTags){
        List<String> lTags = (sTags != null)? new List<String>(stags) : new List<String>();
        List<B2BCartToOrderOutput> lOutputs = new List<B2BCartToOrderOutput>{
            new B2BCartToOrderOutput(
                displayErrorMessage,      // errorTxt
                null,                  // orderId 
                true,                  // showError
                false,                 // deleteCart
                false                  // isOrderOk
            )
        };
        Logger.error(errorMsg).addTags(lTags);
        Logger.error('[NB2B_CartToOrder - lOutputs]: ' + JSON.serializePretty(lOutputs)).addTags(lTags);
        Logger.saveLog();
        return lOutputs;
    }

    @TestVisible
    private static void createError(String errorMsg, Set<String> sTags){
        List<String> lTags = (sTags != null)? new List<String>(stags) : new List<String>();
        Logger.error(errorMsg).addTags(lTags);
        Logger.saveLog();
    }

    @TestVisible
    private static List<B2BCartToOrderOutput> createError(CartToOrderException e){
        return createError(e.getMessage(),e.getDisplayMessage(),new Set<String>{'NB2B_CartToOrder'});
    }

    private static List<B2BCartToOrderOutput> createError(B2BCartToOrderOutput outputItem, Set<String> sTags){
        List<String> lTags = (sTags != null)? new List<String>(stags) : new List<String>();
        List<B2BCartToOrderOutput> lOutputs = new List<B2BCartToOrderOutput>{
            outputItem
        };
        Logger.error('[NB2B_CartToOrder - lOutputs]: ' + JSON.serializePretty(lOutputs)).addTags(lTags);
        Logger.saveLog();
        return lOutputs;
    }

    @TestVisible
    private class CartToOrderException extends Exception {
        private String displayMsg;

        /**
         * @description Setter method for DisplayMessage
         * @param displayMsg - String with display message.
         * @return self instance
         * /
        public CartToOrderException setDisplayMessage(String displayMsg){
            this.displayMsg = displayMsg;
            return this;
        }

        /**
         * @description Getter for Display Message
         * @return displayMsg value
         * /
        public String getDisplayMessage(){return this.displayMsg; }
    }
        */
}