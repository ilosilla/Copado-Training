/**
 * @author         Ramón Prades
 * @date           January 2026
 * @layer          Builder
 * @description    Builder class to assist creating a sales order from a cart
*/
public without sharing class B2B_CommerceOrderBuilder {

    public static final String PAYMENT_CREDIT = 'CREDIT';
    public static final String PAYMENT_PREPAID = 'PREPAID';
    public static final String PAYMENT_DEPOSIT = 'DEPOSIT';
    public static final String PAYMENT_NONE = 'NONE';
    
    private ConnectApi.CartSummary cart;
    private ConnectApi.CartItem[] cartItems;
    private Id accountId;
    private Id webstoreId; 
    private String salesOrg;
    private String distributionChannel;
    private String salesOffice;
    private Id pricebookId;
    private SystemLog logger;
    private AddressDTO billingAddress;
    private Product2 freightProduct;
    private Product2 cardSurchargeProduct; 

    // Additional order properties
    private String poNumber;
    private String paymentModel = PAYMENT_NONE;
    private Decimal creditCardSurcharge = 0;
    private Decimal creditCardSurchargePct = 0;

    // Created records
    private Order order;
    private OrderItem[] orderItems;
    private OrderDeliveryGroup orderDeliveryGroup;   
    private Id orderDeliveryMethodId;
    private ConnectApi.OrderSummaryOutputRepresentation orderSummaryOutput;

    /**
     * Constructor
     */
    public B2B_CommerceOrderBuilder(ConnectApi.CartSummary cart, ConnectApi.CartItem[] cartItems) {
        this.logger = new SystemLog('B2B-ORDER');
        this.logger.setTag('CartToOrder');        
        this.cart = cart;
        this.cartItems = cartItems;
        this.logger.addInfo('Converting cart ' + this.cart.cartId + ' to order');
        this.logger.addInfo('The custom fields are ' + JSON.serialize(this.cart.customFields));
    }

    /**
     * Optional setters (fluent)
     */
    public B2B_CommerceOrderBuilder withPaymentModel(String value) {
        this.paymentModel = value;
        return this;
    }

    public B2B_CommerceOrderBuilder withPoNumber(String value) {
        this.poNumber = value;
        return this;
    }
    
    /**
     * Set the Credit Card surcharge.
     * Value, not percentage, as the calculation is done in the frontend to avoid rounding issues
     */
    public B2B_CommerceOrderBuilder withCreditCardSurcharge(Decimal value) {    
        this.creditCardSurcharge = value;
        return this;
    }

    public B2B_CommerceOrderBuilder withCreditCardSurchargePct(Decimal value) {    
        this.creditCardSurchargePct = value;
        return this;
    }

    /**
     * Build the order (not saved yet, just in memory, fluent)
     */

    public B2B_CommerceOrderBuilder build() {  
        try {
            Set<Id> cdgIds = new Set<Id>();
            this.prepareBuilder();
            this.logger.addInfo('Builder prepared for account ' + this.accountId);
            this.logger.addInfo('SalesOrg/Channel/Sales Office are ' + this.salesOrg + '/' + this.distributionChannel + '/' + this.salesOffice);        

            this.orderItems = new List<OrderItem>();
            
            // Order items
            for (ConnectApi.CartItem cartItem : this.cartItems) {
                this.orderItems.add(mapCartItemToOrderItem(cartItem));
                cdgIds.add(cartItem.cartDeliveryGroupId);
            } 

            // Premise: Just one CDG is used in the cart
            if (cdgIds.size() != 1) {
                throw new ContextException('Only one Cart Delivery Group per order is supported. Found ' + cdgIds.size());
            }

            // Order delivery group and order delivery method
            Id cdgId = new List<Id>(cdgIds)[0];
            this.orderDeliveryGroup = this.mapDeliveryGroup(cdgId);
            this.logger.addInfo('Order delivery group mapped with delivery method ' + this.orderDeliveryGroup.OrderDeliveryMethodId);

            // Adds an item for the freight if applicable
            Decimal freightAmount = Decimal.valueOf(this.cart.TotalChargeAmount) ?? 0;
            if (freightAmount > 0) {
                this.addFreightItem(freightAmount);
                this.logger.addInfo('Freight amount in cart is ' + freightAmount);
            }

            //And credit card surcharge if applicable
            if (this.creditCardSurcharge > 0) {
                this.addCardSurchargeItem(this.creditCardSurcharge);
                this.logger.addInfo('Credit card surcharge amount is ' + this.creditCardSurcharge);
                this.logger.addInfo('Credit card surcharge percentage is ' + this.creditCardSurchargePct);
            }

            // Order header (this is the last because we need the order delivery group)
            this.order = this.mapCartToOrderHeader();  

            this.logger.addInfo('Order built successfully in memory.');
            this.logger.saveLog();
        } catch (Exception e) {           
            this.logger.addError(e);
            SystemLog.writeLog(JSON.serialize(this.logger));
            throw e;
        }
        
        return this;
    }

    /**
     * Save the order built with the builder (fluent)
     */
    public B2B_CommerceOrderBuilder save() {
        if (this.order == null) {
            this.build();
        }
        try {
            this.logger.addInfo('Saving order to database');            
            OrdersService.createOrder(this.order, this.orderItems, this.orderDeliveryGroup);
            this.logger.addInfo('Order saved successfully with id ' + this.order.Id + ' and order number ' + this.order.OrderNumber);
            this.postSaveTasks(this.order.Id);
            this.logger.saveLog();
        } catch (Exception e) {
            this.logger.addError(e);
            SystemLog.writeLog(JSON.serialize(this.logger));
            throw e;
        }

        return this;
    }

    /** 
     * Creates the summary if requested
     */
    public B2B_CommerceOrderBuilder createSummary() {
        if (this.order == null || this.order.Id == null) {
            throw new ContextException('Order must be built and saved before creating the summary');
        }
        try {
            this.logger.addInfo('Creating order summary for order ' + this.order.Id);
            this.order.Status = OrdersDomain.STATUS_ACTIVATED;
            update this.order;
            this.logger.addInfo('Order activated successfully');
            ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = new ConnectApi.OrderSummaryInputRepresentation();
            orderSummaryInput.businessModel = 'B2B';
            orderSummaryInput.orderId = this.order.Id;
            orderSummaryInput.sourceProcess = 'Standard';
            this.orderSummaryOutput = ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);
            this.logger.addInfo('Order Summary created with Id ' + this.orderSummaryOutput.orderSummaryId);
            this.logger.saveLog();
        } catch (Exception e) {
            this.logger.addError(e);
            SystemLog.writeLog(JSON.serialize(this.logger));
            throw e;
        }
        return this;
    }

    public Order getOrder() {
        return this.order;
    }

    public OrderItem[] getOrderItems() {
        return this.orderItems;
    }

    public OrderDeliveryGroup getOrderDeliveryGroup() {
        return this.orderDeliveryGroup;
    }

    public ConnectApi.OrderSummaryOutputRepresentation getOrderSummaryOutput() {
        return this.orderSummaryOutput;
    }

    /* *************************** PRIVATE METHODS *************************** */

    /**
     * Post save tasks
     */
    private void postSaveTasks(Id orderId) {
        // Update payment
        PaymentRequest__c[] payments = [select Id, Order__c from PaymentRequest__c where Order__c = null and CartId__c = :this.cart.cartId];
        if (payments.size() > 0) {
            for (PaymentRequest__c payment : payments) {
                payment.Order__c = orderId; 
                payment.Status__c = B2B_PaymentsService.COMPLETED_STATUS;        
            }
            update payments;    
        }

        // Update delivery requirements
        DeliveryRequirement__c[] deliveryRequirements = [select Id, Order__c from DeliveryRequirement__c where Order__c = null and Cart__c = :this.cart.cartId];
        if (deliveryRequirements.size() > 0) {
            for (DeliveryRequirement__c dr : deliveryRequirements) {
                dr.Order__c = orderId;
            }        
            update deliveryRequirements;        
        }
    }

    /**
     * Prepares the builder by reading te auxiliary object needed later
     */
    private void prepareBuilder() {
        Product2[] products = [select Id, Name, StockKeepingUnit from Product2 where StockKeepingUnit in ('FLETE', 'CC_FEE')];
        for (Product2 p : products) {
            if (p.StockKeepingUnit == 'FLETE') {
                this.freightProduct = p;
            } else if (p.StockKeepingUnit == 'CC_FEE') {
                this.cardSurchargeProduct = p;
            }
        }
        User currentUser = [SELECT Id, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c from User WHERE Id = :UserInfo.getUserId() limit 1];
        this.salesOrg = currentUser.Default_Sales_Organization__c;
        this.distributionChannel = currentUser.Distribution_channel_default__c;
        this.salesOffice = currentUser.Sales_Office__c;
        this.accountId = this.cart.accountId;        
        this.webstoreId = this.cart.webstoreId;
        this.billingAddress = AddressDTO.readFromAccount(accountId);
        // this.pricebookId = B2B_CommerceUtils.getApplicablePricebookId(this.accountId, this.webstoreId);
        this.orderDeliveryMethodId = this.getOrderDeliveryMethodForFreight();
    }

    /**
     * Maps cart to order header (Order)
     */
    private Order mapCartToOrderHeader() {        
        Order o = new Order();        
        o.EffectiveDate = Date.today();
        o.Version__c = OrdersDomain.VERSION3;
        o.Type = OrdersDomain.MATERIALS_ORDER;
        o.AccountId = this.accountId;
        o.SalesOrg__c = this.salesOrg;        
        o.Distribution_channel__c = this.distributionChannel;
        o.SalesOffice__c = this.salesOffice;
        o.CurrencyIsoCode = this.cart.currencyIsoCode;
        o.Status = OrdersDomain.STATUS_DRAFT;
        o.PoNumber = o.PoNumber = String.isNotBlank(this.poNumber)
                        ? this.poNumber
                        : this.cart.purchaseOrderNumber;
        o.PoDate = o.EffectiveDate;
        o.SalesStoreId = this.webstoreId;
        // o.Pricebook2Id = this.pricebookId;

        // Billing address
        o.BillingCity = this.billingAddress.city;
        o.BillingCountry = this.billingAddress.country;
        o.BillingCountryCode = this.billingAddress.countryCode;
        o.BillingPostalCode = this.billingAddress.postCode;
        o.BillingState = this.billingAddress.state;
        o.BillingStateCode = this.billingAddress.stateCode;
        o.BillingStreet = this.billingAddress.street;

        // Shipping address
        o.ShippingCity = this.orderDeliveryGroup.DeliverToCity;
        o.ShippingCountry = this.orderDeliveryGroup.DeliverToCountry;
        o.ShippingCountryCode = this.orderDeliveryGroup.DeliverToCountryCode;
        o.ShippingPostalCode = this.orderDeliveryGroup.DeliverToPostalCode;
        o.ShippingState = this.orderDeliveryGroup.DeliverToState;
        o.ShippingStateCode = this.orderDeliveryGroup.DeliverToStateCode;
        o.ShippingStreet = this.orderDeliveryGroup.DeliverToStreet;
        o.StorePickup__c = (this.orderDeliveryGroup.DeliveryMethod__c == 'CUSTOMER-PICKUP');

        // Tax and amount fields
        o.TaxLocaleType = 'Net'; // US

        // Other fields
        o.Origin__c  = 'B2B';
        o.PaymentModel__c = this.paymentModel;
       
        return o;
    }

    /**
     * Maps a cartItem into an order item
     */
    private OrderItem mapCartItemToOrderItem(ConnectApi.CartItem cartItem) {
        CartItem customFields = null;
        if (cartItem.customFields.size() > 0) {
            customFields = (CartItem) cartItem.customFields[0];
        }
        OrderItem oItem = new OrderItem();
        oItem.Product2Id = cartItem.productId;        
        oItem.CustomName__c = cartItem.name;
        oItem.Quantity = Decimal.valueOf(cartItem.quantity) ?? 0;
        oItem.SalesUnit__c = customFields?.SalesPriceUnit__c;

        //oItem.GrossUnitPrice = Decimal.valueOf(cartItem.salesPrice) ?? 0;
        oItem.UnitPrice = Decimal.valueOf(cartItem.salesPrice) ?? 0;
        oItem.UnitPriceUnitCode__c =  oItem.SalesUnit__c ;        
        oItem.ListPrice = Decimal.valueOf(cartItem.SalesPrice) ?? 0;
        oItem.ListPriceUnitCode__c = customFields?.SalesPriceUnit__c;   
        oItem.TotalLineAmount = Decimal.valueOf(cartItem.totalPrice) ?? 0;    

        oItem.Type = 'Order Product';
        return oItem;
    }

    /**
     * Adds an order item for the freight charge
     */
    private void addFreightItem(Decimal amount) {
        OrderItem freightItem = new OrderItem();
        freightItem.Product2Id = this.freightProduct.Id;
        freightItem.CustomName__c = 'SHIPPING CHARGE';
        freightItem.Quantity = 1;
        freightItem.SalesUnit__c= 'UN';

        freightItem.GrossUnitPrice = amount;
        freightItem.UnitPrice = amount;
        freightItem.ListPrice = amount;
        freightitem.ListPriceUnitCode__c = 'UN';
        freightItem.TotalLineAmount = amount; 
        freightItem.Type = 'Delivery Charge';
        this.orderItems.add(freightItem);
    }

    /**
     * Adds an order item for the credit card surcharge
     */
    private void addCardSurchargeItem(Decimal amount) {
        OrderItem item = new OrderItem();
        item.Product2Id = this.cardSurchargeProduct.Id;
        item.CustomName__c = 'CREDIT CARD SURCHARGE' + (this.creditCardSurchargePct > 0 ? ' (' + this.creditCardSurchargePct + '%)' : '');
        item.Quantity = 1;
        item.SalesUnit__c= 'UN';

        item.GrossUnitPrice = amount;
        item.UnitPrice = amount;
        item.ListPrice = amount;
        item.ListPriceUnitCode__c = 'UN';
        item.TotalLineAmount = amount; 
        item.Type = 'Fee';
        this.orderItems.add(item);
    }

    /**
     * Maps a CartDeliveryGroup into an OrderDeliveryGroup
     */
    private OrderDeliveryGroup mapDeliveryGroup(Id cdgId) {
        CartDeliveryGroup cdg = this.getCartDeliveryGroup(cdgId);
        OrderDeliveryGroup odg = new OrderDeliveryGroup();        

        // Prepare variables
        String deliverToName = cdg.ContactPointAddressId__r?.Name ?? cdg.CollectionPoint__r?.Name;
        String sapId = cdg.ContactPointAddressId__r?.SAPId__c ?? cdg.CollectionPoint__r?.NBK_SAPId__c;  

        // --- Mandatory relationship
        // odg.OrderId = orderId;

        // --- Currency (must be set explicitly)
        // odg.CurrencyIsoCode = cdg.CurrencyIsoCode;

        // =====================================================
        // DELIVERY ADDRESS
        // =====================================================
        odg.DeliverToName            = deliverToName;
        odg.DeliverToCompanyName     = cdg.CompanyName;
        odg.DeliverToStreet          = cdg.DeliverToStreet;
        odg.DeliverToCity            = cdg.DeliverToCity;
        odg.DeliverToState           = cdg.DeliverToState;
        odg.DeliverToStateCode       = cdg.DeliverToStateCode;
        odg.DeliverToPostalCode      = cdg.DeliverToPostalCode;
        odg.DeliverToCountry         = cdg.DeliverToCountry;
        odg.DeliverToCountryCode     = cdg.DeliverToCountryCode;
        odg.SAPId__c                 = sapId;
        odg.ContactPointAddress__c   = cdg.ContactPointAddressId__c;
        odg.PorcelanosaAddress__c    = cdg.CollectionPoint__c;
        odg.DeliveryMethod__c        = cdg.DeliveryMethod__c;

        // Geolocation (optional but safe)
        odg.DeliverToLatitude        = cdg.DeliverToLatitude;
        odg.DeliverToLongitude       = cdg.DeliverToLongitude;
        odg.DeliverToGeocodeAccuracy = cdg.DeliverToGeocodeAccuracy;

        // =====================================================
        // CONTACT DETAILS
        // =====================================================
        odg.PhoneNumber   = cdg.ShipToPhoneNumber;
        odg.EmailAddress = null; // no equivalent in CartDeliveryGroup (keep explicit)

        // =====================================================
        // DELIVERY METHOD
        // =====================================================
        odg.OrderDeliveryMethodId = this.orderDeliveryMethodId;

        // =====================================================
        // DATES & INSTRUCTIONS
        // =====================================================
        Date cartDeliveryDate = null;
        String cartSpecialInstructions = '';
        if (!this.cart.customFields.isEmpty()) {
            WebCart customFields = (WebCart) this.cart.customFields[0];
            cartDeliveryDate = customFields.DeliveryDate__c;
            cartSpecialInstructions = customFields.SpecialInstructions__c;
        }
        odg.DesiredDeliveryDate = cartDeliveryDate;
        odg.DeliveryInstructions = cartSpecialInstructions;

        // =====================================================
        // CUSTOM FIELDS
        // =====================================================
        odg.SAPId__c = cdg.SalesOrg__c;

        // =====================================================
        // OPTIONAL DESCRIPTION (debug / traceability)
        // =====================================================
        odg.Description = 'Generated from CartDeliveryGroup ' + cdg.Id;

        return odg;
    }

    private CartDeliveryGroup getCartDeliveryGroup(Id cartDeliveryGroupId) {
        return [
            SELECT
                Id,
                CurrencyIsoCode,

                /* Company / recipient */
                CompanyName,
                DeliverToName,

                /* Address */
                DeliverToStreet,
                DeliverToCity,
                DeliverToState,
                DeliverToStateCode,
                DeliverToPostalCode,
                DeliverToCountry,
                DeliverToCountryCode,

                /* Geo */
                DeliverToLatitude,
                DeliverToLongitude,
                DeliverToGeocodeAccuracy,

                /* Contact */
                ShipToPhoneNumber,

                /* Delivery */
                DeliveryMethodId,
                DesiredDeliveryDate,
                ShippingInstructions,

                /* Amounts */
                GrandTotalAmount,
                TotalChargeAmount,
                TotalProductAmount,
                TotalTaxAmount,

                /* Custom */
                SalesOrg__c,
                DeliveryMethod__c,
                ContactPointAddressId__c,
                ContactPointAddressId__r.Name, 
                ContactPointAddressId__r.SAPId__c, 
                CollectionPoint__c, 
                CollectionPoint__r.Name, 
                CollectionPoint__r.NBK_SAPId__c                

            FROM CartDeliveryGroup
            WHERE Id = :cartDeliveryGroupId
            AND IsDeleted = FALSE
            LIMIT 1
        ];
    }

    /**
     * Finds the Order Delivery Method linked to the freight product
     */
    private Id getOrderDeliveryMethodForFreight() {
        Id odmId = null;
        OrderDeliveryMethod[] existing = [select Id from OrderDeliveryMethod where ProductId = :freightProduct.Id];
        if (existing.size() == 0) {
            OrderDeliveryMethod odm = new OrderDeliveryMethod();
            odm.Name = 'FLETE';
            odm.ProductId = freightProduct.Id;
            odm.IsActive = true;
            odm.Description = 'B2B delivery method for FLETE';
            insert odm;   
            odmId = odm.Id;
        } else {
            odmId = existing[0].Id;
        }
        return odmId;
    }

    public class BuiltOrderDTO {
        public Order order;
        public OrderItem[] orderItems;
        public OrderDeliveryGroup orderDeliveryGroup;
    }

}