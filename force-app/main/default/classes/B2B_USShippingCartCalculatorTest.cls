@isTest public with sharing class B2B_USShippingCartCalculatorTest {

    private static final String FLETE_SKU = 'FLETE-01';

    @testSetup private static void testSetup() {
        DataFactoryECommerce factory = new DataFactoryEcommerce();
        factory.buildEcommerce();
        factory.createCart();
    }

    @IsTest
    static void testCalculate_createsZeroCostMethodWhenReset() {
        setupShippingProduct();
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cartObject, CartExtension.OptionalBuyerActionDetails.empty());
        CartExtension.CartDeliveryGroup deliveryGroup2 = cartObject.getCartDeliveryGroups().get(0);
        deliveryGroup2.setCustomField('ContactPointAddressId__c', null);
        deliveryGroup2.setCustomField('PorcelanosaAddress__c', null);

        Test.startTest();
        B2B_USShippingCartCalculator.SHIPPING_SKU = FLETE_SKU;
        new B2B_USShippingCartCalculator().calculate(request);
        Test.stopTest();

        CartExtension.CartDeliveryGroup deliveryGroup = cartObject.getCartDeliveryGroups().get(0);
        CartExtension.CartDeliveryGroupMethod selectedMethod = deliveryGroup.getSelectedCartDeliveryGroupMethod();
        Assert.areEqual(0, cartObject.getCartValidationOutputs().size(), 'No validation error expected for reset.');
        Assert.areEqual(1, deliveryGroup.getCartDeliveryGroupMethods().size(), 'One delivery method should be created.');
        Assert.areNotEqual(null, selectedMethod, 'A delivery method should be selected.');
        Assert.areEqual(0, selectedMethod.getShippingFee(), 'Cost should be zero when reset.');
        Assert.isNull(deliveryGroup.getDeliverToAddress()?.getCity(), 'DeliverTo fields should be cleared when reset.');
    }

    @IsTest
    static void testCalculate_createsZeroCostMethodWhenPickup() {
        setupShippingProduct();
        DataFactoryPorcelanosaAddress.createAddresses();
      
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartDeliveryGroup cdg = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cart.Id LIMIT 1];
        cdg.DeliveryMethod__c     = 'CUSTOMER-PICKUP';
        cdg.PorcelanosaAddress__c = [SELECT Id FROM PorcelanosaAddress__c LIMIT 1].Id;
        update cdg;

        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        CartExtension.CartCalculateCalculatorRequest request =
            new CartExtension.CartCalculateCalculatorRequest(cartObject, CartExtension.OptionalBuyerActionDetails.empty());

        Test.startTest();
        B2B_USShippingCartCalculator.SHIPPING_SKU = FLETE_SKU;
        new B2B_USShippingCartCalculator().calculate(request);
        Test.stopTest();

        CartExtension.CartDeliveryGroup deliveryGroup = cartObject.getCartDeliveryGroups().get(0);
        CartExtension.CartDeliveryGroupMethod selectedMethod = deliveryGroup.getSelectedCartDeliveryGroupMethod();
        Assert.areEqual(0, cartObject.getCartValidationOutputs().size(), 'No validation error expected for pickup.');
        Assert.areEqual(1, deliveryGroup.getCartDeliveryGroupMethods().size(), 'One delivery method should be created.');
        Assert.areEqual(0, selectedMethod.getShippingFee(), 'Cost should be zero for pickup.');
        Assert.areEqual('Customer pickup', selectedMethod.getName(), 'Method name should indicate pickup.');
    }

    @IsTest
    static void testCalculate_createsMethodWithStoredCostWhenShipToCustomer() {
        setupShippingProduct();
        Id accountId = [SELECT AccountId FROM WebCart LIMIT 1].AccountId;
        ContactPointAddress cpa = new ContactPointAddress(
            ParentId   = accountId, AddressType = 'Shipping',
            Name = 'Test Address', CountryCode = 'US', StateCode = 'NJ',
            City = 'Saddle River', Street = '1 Test St', PostalCode = '07401'
        );
        insert cpa;

        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartDeliveryGroup cdg = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cart.Id LIMIT 1];
        cdg.DeliveryMethod__c        = 'SHIP-TO-CUSTOMER';
        cdg.ContactPointAddressId__c = cpa.Id;
        cdg.ShippingCost__c          = 150;
        update cdg;

        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        CartExtension.CartCalculateCalculatorRequest request =
            new CartExtension.CartCalculateCalculatorRequest(cartObject, CartExtension.OptionalBuyerActionDetails.empty());

        Test.startTest();
        B2B_USShippingCartCalculator.SHIPPING_SKU = FLETE_SKU;
        new B2B_USShippingCartCalculator().calculate(request);
        Test.stopTest();

        CartExtension.CartDeliveryGroup deliveryGroup = cartObject.getCartDeliveryGroups().get(0);
        CartExtension.CartDeliveryGroupMethod selectedMethod = deliveryGroup.getSelectedCartDeliveryGroupMethod();
        Assert.areEqual(0, cartObject.getCartValidationOutputs().size(), 'No validation error expected for ship-to-customer.');
        Assert.areEqual(1, deliveryGroup.getCartDeliveryGroupMethods().size(), 'One delivery method should be created.');
        Assert.areEqual(150, selectedMethod.getShippingFee(), 'Cost should match ShippingCost__c stored on CDG.');
        Assert.areEqual('Standard shipping', selectedMethod.getName(), 'Method name should indicate standard shipping.');
        Assert.areEqual('Saddle River', deliveryGroup.getDeliverToAddress().getCity(), 'DeliverTo city should be set from CPA.');
        // Assert.areEqual('NJ', deliveryGroup.getDeliverToAddress().getStateCode(), 'DeliverTo state should be set from CPA.');
    }

    @IsTest
    static void testCalculate_addsValidationWhenShippingProductIsMissing() {
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
        CartExtension.CartCalculateCalculatorRequest request =
            new CartExtension.CartCalculateCalculatorRequest(cartObject, CartExtension.OptionalBuyerActionDetails.empty());

        Test.startTest();
        B2B_USShippingCartCalculator.SHIPPING_SKU = 'MISSING-SKU';
        new B2B_USShippingCartCalculator().calculate(request);
        Test.stopTest();

        CartExtension.CartValidationOutputList validations = cartObject.getCartValidationOutputs();
        Assert.areEqual(1, validations.size(), 'A shipping validation should be added when no shipping product is configured.');
        Assert.areEqual(CartExtension.CartValidationOutputTypeEnum.SHIPPING, validations.get(0).getType(), 'The validation should be a shipping error.');
        Assert.areEqual(0, cartObject.getCartDeliveryGroups().get(0).getCartDeliveryGroupMethods().size(), 'No delivery method should be created without a shipping product.');
    }

    private static void setupShippingProduct() {
        List<Product2> products = [SELECT Id FROM Product2];
        if (!products.isEmpty()) {
            products[products.size() - 1].StockKeepingUnit = FLETE_SKU;
            products[products.size() - 1].Name = 'SHIPPING CHARGE';
            update products;
        }
    }
}