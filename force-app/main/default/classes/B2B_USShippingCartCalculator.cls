/**
 * @author         Ramón Prades
 * @date           December 2025
 * @group          B2B
 * @description    Shipping applicator for the US dealers site.
 *                 This class acts as an APPLICATOR, not a calculator.
 *                 Shipping cost is pre-calculated by B2B_USCheckoutController.calculateShipping()
 *                 and stored in CartDeliveryGroup custom fields. This class reads those values
 *                 and formalises them via the CartExtension API so the platform updates
 *                 CartDeliveryGroup.TotalChargeAmount correctly.
 *                 -----------------------------------------------------
 *                 This is an implementation of Salesforce example class
 *                 CartExtension.ShippingCartCalculator.
 *                 -----------------------------------------------------
 *  This class must extend CartExtension.ShippingCartCalculator to be processed.
 *  It must be linked to the Shipping Calculator extension point and the integration
 *  must be linked to the webstore via the appropriate Setup.
 */

public class B2B_USShippingCartCalculator extends CartExtension.ShippingCartCalculator {

    public static String SHIPPING_SKU = 'FLETE';
    //private static final Decimal LB_PER_KG = 2.20462;

    // Instance variables
    CartExtension.CartDeliveryGroup deliveryGroup;
    String deliveryMethod = null;
    String contactAddressId = null;
    String warehouseAddressId = null;
    String shippingProductId = null;
    String shippingName;
    Decimal shippingCost = 0;
    Decimal weightInKg = 0;
    Boolean isPickup = false;
    String currencyCode = 'USD';
    String shippingExplanation = '';

    /**
     * Calculates the shipping charge for the cart. This method is called by the platform during cart calculation.
     */
    public override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        this.deliveryGroup      = cart.getCartDeliveryGroups().get(0);
        this.deliveryMethod     = (String) this.deliveryGroup.getCustomField('DeliveryMethod__c');
        this.contactAddressId   = (String) this.deliveryGroup.getCustomField('ContactPointAddressId__c');
        this.warehouseAddressId = (String) this.deliveryGroup.getCustomField('PorcelanosaAddress__c');

        CartExtension.CartValidationOutputList validations = cart.getCartValidationOutputs();
        PB2B_CartCommons.clearShippingValidations(validations);
        if (!validateDeliveryGroups(cart, validations)) { return; }

        this.shippingProductId = this.getShippingProduct();
        if (this.shippingProductId == null) {
            validations.add(createShippingError('No shipping product has been configured [SHIPPING_CALC_003]'));
            return;
        }
        
        this.resetDeliveryMethods(this.deliveryGroup);

        Boolean isReset  = (this.contactAddressId == null) && (this.warehouseAddressId == null);
        Boolean isPickup = 'CUSTOMER-PICKUP'.equals(this.deliveryMethod);

        this.deliveryGroup.setCustomField('ShippingPending__c', false);
        if (isReset) {
            this.shippingName = 'Reset Shipping';
            this.shippingCost = 0;
            this.deliveryGroup.setDeliverToName(null);
            this.deliveryGroup.setDeliverToStreet(null);
            this.deliveryGroup.setDeliverToCity(null);
            this.deliveryGroup.setDeliverToState(null);
            this.deliveryGroup.setDeliverToPostalCode(null);
            this.deliveryGroup.setDeliverToCountry(null);            
            //return;
        } else if (isPickup) {
            this.shippingName = 'Customer pickup';
            this.shippingCost = 0;
        } else {
            this.shippingName = 'Standard shipping';
            this.shippingCost = (Decimal) this.deliveryGroup.getCustomField('ShippingCost__c') ?? 0;
            ContactPointAddress cpa = [
                SELECT Name, Street, City, StateCode, PostalCode, CountryCode
                FROM ContactPointAddress WHERE Id = :this.contactAddressId LIMIT 1
            ];
            this.deliveryGroup.setDeliverToName(cpa.Name);
            this.deliveryGroup.setDeliverToStreet(cpa.Street);
            this.deliveryGroup.setDeliverToCity(cpa.City);
            this.deliveryGroup.setDeliverToState(cpa.StateCode);
            this.deliveryGroup.setDeliverToPostalCode(cpa.PostalCode);
            this.deliveryGroup.setDeliverToCountry(cpa.CountryCode);
        }

        this.createAndSelectMethod();
    }
    // ─── Private helpers ────────────────────────────────────────────────────────
    
    /**
     * Creates the delivery method and selects it in the delivery group.
     */    
    private void createAndSelectMethod() {
        CartExtension.CartDeliveryGroupMethod method = new CartExtension.CartDeliveryGroupMethod(this.shippingName, this.shippingCost, this.shippingProductId);
        method.setIsActive(true);
        this.deliveryGroup.getCartDeliveryGroupMethods().add(method);
        this.deliveryGroup.setSelectedCartDeliveryGroupMethod(method);
    }

    /**
     * Validates that there is exactly one delivery group in the cart.
     */
    private Boolean validateDeliveryGroups(CartExtension.Cart cart, CartExtension.CartValidationOutputList validations) {
        CartExtension.CartDeliveryGroupList groups = cart.getCartDeliveryGroups();

        if (groups.isEmpty()) {
            validations.add(createShippingError('No delivery address found for this cart [SHIPPING_CALC_001]'));
            return false;
        }

        if (groups.size() > 1) {
            validations.add(createShippingError('Multiple delivery addresses found for this cart [SHIPPING_CALC_002]'));
            return false;
        }

        return true;
    }

    /**
     * Resets existing delivery methods in the delivery group.
     */
    private void resetDeliveryMethods(CartExtension.CartDeliveryGroup cdg) {
        CartExtension.CartDeliveryGroupMethodList methods = cdg.getCartDeliveryGroupMethods();
        methods.clear();
        cdg.setSelectedCartDeliveryGroupMethod(null);
    }

    /**
     * Retrieves the shipping product used for the shipping charge line.
     */
    private Id getShippingProduct() {
        List<Product2> products = [
            SELECT Id
            FROM Product2
            WHERE StockKeepingUnit = :SHIPPING_SKU
        ];
        if (products.isEmpty()) {
            return null;
        }
        return products[0].Id;
    }

    /**
     * Calculates the total weight of the cart in kg
    private Decimal getCartWeightInKg(CartExtension.Cart cart) {
        Decimal total = 0;
        CartExtension.CartItemList cartItems = cart.getCartItems();
        Iterator<CartExtension.CartItem> cartItemIterator = cartItems.iterator();
        while (cartItemIterator.hasNext()) {
            CartExtension.CartItem item = cartItemIterator.next();
            if ('Product'.equalsIgnoreCase(item.getType().toString())) {
                Decimal itemWeight = item.getTotalWeight() ?? 0;
                if (itemWeight == 0) {
                    Map<String, Object> context = new Map<String, Object>{
	                    'System' => 'B2B',
	                    'Class' => 'B2B_USShippingCartCalculator',
	                    'Method' => 'getCartWeightInKg',
                        'Product' => item.getProduct2Id(),
                        'CartId' => cart.getId()
                    };
                    String[] hints = new List<String> {
                        'Posiblemente el peso es cero en el objeto Product2. Revisar campos ShippingWeight y ShippingWeightUnitOfMeasure'
                    };
                    SystemAlert alert = new SystemAlert('B2B - SHIPPING COST ERROR', SystemAlert.Severity.HIGH)
	                    .withContext(context)
	                    .withHints(hints)
                    	.withDedupKey('B2B_SHIPPING_COST_ERROR_' + item.getProduct2Id());
                    SystemAlertService.notify(alert);
                    throw new ContextException('Weight is required for all products in the cart to calculate shipping. Please update the product weight and try again.');                    
                }
                total += item.getTotalWeight() ?? 0;
            }
        }
        return total;
    }
    */


    /**
     * Creates a shipping validation error output.
     */
    private CartExtension.CartValidationOutput createShippingError(String message) {
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
            CartExtension.CartValidationOutputTypeEnum.SHIPPING,
            CartExtension.CartValidationOutputLevelEnum.ERROR
        );
        cvo.setMessage(message);
        return cvo;
    }

    // ─── DTOs ────────────────────────────────────────────────────────────────────

    public class ShippingResultDTO {
        @AuraEnabled public String  addressId;
        @AuraEnabled public Boolean isPickup;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String  isoCurrency;
        @AuraEnabled public String  weight;
        @AuraEnabled public Decimal rate;
        @AuraEnabled public String  perEach;
        @AuraEnabled public String  name;
        @AuraEnabled public String  debugText;
    }

} // class