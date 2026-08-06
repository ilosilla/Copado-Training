@IsTest
public with sharing class B2B_USCheckoutControllerTest {

    @TestSetup
    private static void testSetup() {
        DataFactoryECommerce factory = new DataFactoryEcommerce();
        factory.buildEcommerce();
        factory.createCart();
    }

    @IsTest
    private static void testSaveCartData_updatesCustomerReferenceOnCart() {
        WebCart cart = [SELECT Id, PONumber FROM WebCart LIMIT 1];

        Test.startTest();
        B2B_USCheckoutController.saveCartData(cart.Id, 'PO-123');
        Test.stopTest();

        WebCart refreshedCart = [
            SELECT Id, PONumber
            FROM WebCart
            WHERE Id = :cart.Id
            LIMIT 1
        ];
        Assert.areEqual('PO-123', refreshedCart.PONumber, 'The customer reference should be saved into the cart PO number.');
    }

    @IsTest
    private static void testSaveCartData_throwsWhenCartIdIsMissing() {
        try {
            B2B_USCheckoutController.saveCartData(null, 'PO-123');
            Assert.fail('An AuraHandledException should be thrown when cartId is missing.');
        } catch (AuraHandledException ex) {
            Assert.isNotNull(ex, 'An AuraHandledException should be raised when cartId is missing.');
        }
    }

    @IsTest
    private static void testGetCheckoutInfo_returnsExpectedCheckoutContext() {
        CheckoutTestDataDTO data = arrangeCheckoutInfoData();

        Test.startTest();
        B2B_USCheckoutController.CheckoutInfoDTO dto =
            B2B_USCheckoutController.getCheckoutInfo(data.cartId, data.accountId, data.cartDeliveryGroupId);
        Test.stopTest();

        Assert.areEqual(data.salesOrg, dto.salesOrg, 'The checkout should expose the current user sales organization.');
        Assert.isNotNull(dto.deliveryAddresses, 'Delivery addresses should always be initialized.');
        Assert.areEqual(2, dto.deliveryAddresses.size(), 'The account should expose its own nominal address plus the shipping address created in the test setup.');
        Assert.areEqual(data.accountId, dto.deliveryAddresses[0].id, 'The account\'s own (nominal) address should always be first in the list.');
        Assert.areEqual('Account', dto.deliveryAddresses[0].className, 'The account address entry should be identifiable as such.');
        Assert.areEqual(data.contactPointAddressId, dto.deliveryAddresses[1].id, 'The shipping address should be mapped into AddressDTO.');
        Assert.areEqual('Shipping', dto.deliveryAddresses[1].addressType, 'The address type should be normalized for the checkout UI.');

        Assert.areEqual(data.warehouseId, dto.warehouseAddress.id, 'The resolved warehouse should be exposed in the DTO.');
        Assert.areEqual('Warehouse', dto.warehouseAddress.addressType, 'The resolved warehouse should be labeled as warehouse for the LWC.');
        Assert.areEqual('Mon-Fri 08:00-17:00', dto.warehouseAddress.additionalInfo, 'Pickup hours should be surfaced in the warehouse address.');

        Assert.areEqual('PO instructions', dto.specialInstructions, 'Special instructions should be read from the cart.');
        Assert.areEqual(Date.newInstance(2026, 4, 15), dto.desiredDeliveryDate, 'Desired delivery date should be read from the cart.');

        Assert.isNotNull(dto.accountSettings, 'Account settings should be present in the checkout context.');
        Assert.areEqual(false, dto.accountSettings.CreditCardAllowed__c, 'Stored account settings should be returned when they exist.');
        Assert.areEqual(3.5, dto.accountSettings.CreditCardSurcharge__c, 'Stored account surcharge should be returned when it exists.');

        Assert.isNotNull(dto.deliveryRequirementsMap, 'Delivery requirements map should always be initialized.');
        Assert.isTrue(dto.deliveryRequirementsMap.containsKey(data.contactPointAddressId), 'The delivery requirement should be keyed by contact point address id.');
        Assert.areEqual(true, dto.deliveryRequirementsMap.get(data.contactPointAddressId).LiftgateRequired__c, 'The checkout should pick the delivery requirement for the selected cart.');

        Assert.isNotNull(dto.salesRepName, 'The sales representative name should be returned.');
        Assert.isNotNull(dto.salesRepEmail, 'The sales representative email should be returned.');

        Assert.isNotNull(dto.warehouseLogistics, 'Warehouse logistics should be calculated.');
        Assert.areEqual(2, dto.warehouseLogistics.preparationDays, 'Preparation days should be copied from the configured warehouse.');
        Assert.areEqual('America/New_York', dto.warehouseLogistics.timeZone, 'The warehouse timezone should be exposed.');
        Assert.areEqual('Mon-Fri 08:00-17:00', dto.warehouseLogistics.customerPickupHours, 'The warehouse pickup hours should be exposed.');
        Assert.areEqual('03:30 PM', dto.warehouseLogistics.cutoffTimeLabel, 'The cutoff label should be formatted for the UI.');
        Assert.areEqual('Ready in 2–3 business days (cutoff 03:30 PM local time).', dto.warehouseLogistics.preparationTimeMessage, 'The logistics message should be built from the warehouse configuration.');
    }

    @IsTest
    private static void testSaveDeliveryRequirement_updatesRequirementAndCartData() {
        WebCart cart = [SELECT Id, SpecialInstructions__c, DeliveryDate__c FROM WebCart LIMIT 1];
        CartDeliveryGroup deliveryGroup = [
            SELECT Id, ContactPointAddressId__c
            FROM CartDeliveryGroup
            WHERE CartId = :cart.Id
            LIMIT 1
        ];

        DeliveryRequirement__c deliveryRequirement = new DeliveryRequirement__c(
            ContactPointAddress__c = deliveryGroup.ContactPointAddressId__c,
            Cart__c = cart.Id,
            LiftgateRequired__c = true,
            DeliveryContactName__c = 'Warehouse desk'
        );

        Test.startTest();
        DeliveryRequirement__c savedRequirement = B2B_USCheckoutController.saveDeliveryRequirement(
            deliveryRequirement,
            'Ring the bell on arrival',
            Date.newInstance(2026, 4, 20)
        );
        Test.stopTest();

        Assert.isNotNull(savedRequirement.Id, 'The delivery requirement should be inserted and returned to the caller.');

        DeliveryRequirement__c refreshedRequirement = [
            SELECT Id, ContactPointAddress__c, Cart__c, LiftgateRequired__c, DeliveryContactName__c
            FROM DeliveryRequirement__c
            WHERE Id = :savedRequirement.Id
            LIMIT 1
        ];
        Assert.areEqual(deliveryGroup.ContactPointAddressId__c, refreshedRequirement.ContactPointAddress__c, 'The saved delivery requirement should remain linked to the selected contact point address.');
        Assert.areEqual(cart.Id, refreshedRequirement.Cart__c, 'The saved delivery requirement should remain linked to the cart.');
        Assert.areEqual(true, refreshedRequirement.LiftgateRequired__c, 'The delivery requirement flags should be persisted.');
        Assert.areEqual('Warehouse desk', refreshedRequirement.DeliveryContactName__c, 'The delivery contact should be persisted.');

        WebCart refreshedCart = [
            SELECT Id, SpecialInstructions__c, DeliveryDate__c
            FROM WebCart
            WHERE Id = :cart.Id
            LIMIT 1
        ];
        Assert.areEqual('Ring the bell on arrival', refreshedCart.SpecialInstructions__c, 'The cart special instructions should be updated.');
        Assert.areEqual(Date.newInstance(2026, 4, 20), refreshedCart.DeliveryDate__c, 'The cart delivery date should be updated.');
    }

    @IsTest
    private static void testRetrieveCreditStatus_throwsWhenAccountIdIsMissing() {
        try {
            B2B_USCheckoutController.retrieveCreditStatus(null);
            Assert.fail('An AuraHandledException should be thrown when accountId is missing.');
        } catch (AuraHandledException ex) {
            Assert.isNotNull(ex, 'An AuraHandledException should be raised when accountId is missing.');
        }
    }

    @IsTest
    private static void testValidatePrices_returnsOkWhenSapValidationIsDisabled() {
        WebCart cart = [SELECT Id, AccountId, WebStoreId FROM WebCart LIMIT 1];
        PORSAStoreSettings__c settings = PORSAStoreSettings__c.getInstance('US_DEALERS');
        if (settings == null) {
            settings = new PORSAStoreSettings__c(Name = 'US_DEALERS');
        }
        settings.StoreId__c = cart.WebStoreId;
        settings.EnableSAPPriceValidation__c = false;
        upsert settings;

        Test.startTest();
        B2B_CommerceOrdersService.PriceValidationResultDTO result =
            B2B_USCheckoutController.validatePrices(cart.WebStoreId, cart.Id, cart.AccountId);
        Test.stopTest();

        Assert.isNotNull(result, 'The controller should always return a result DTO.');
        Assert.areEqual(true, result.isOk, 'When SAP price validation is disabled, the controller should return a successful result.');
    }

    /* Auto */
    @IsTest
    private static void testPrepareShipping_resetsDeliveryGroupAndReturnsWeight() {
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartDeliveryGroup cdg = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cart.Id LIMIT 1];
        cdg.DeliveryMethod__c = 'SHIP-TO-CUSTOMER';
        cdg.ShippingCost__c = 150;
        update cdg;

        Test.startTest();
        B2B_USCheckoutController.ShippingDTO result = B2B_USCheckoutController.prepareShipping(cdg.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a ShippingDTO');
        Assert.isTrue(result.weightKg >= 0, 'weightKg should be non-negative');

        String expectedSalesOrg = [SELECT Default_Sales_Organization__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Default_Sales_Organization__c;
        CartDeliveryGroup refreshed = [SELECT SalesOrg__c, ContactPointAddressId__c, PorcelanosaAddress__c, DeliveryMethod__c, ShippingCost__c FROM CartDeliveryGroup WHERE Id = :cdg.Id LIMIT 1];
        Assert.areEqual(expectedSalesOrg, refreshed.SalesOrg__c,          'SalesOrg should be set from the current user');
        Assert.isNull(refreshed.ContactPointAddressId__c,                  'ContactPointAddressId should be nulled');
        Assert.isNull(refreshed.PorcelanosaAddress__c,                     'PorcelanosaAddress should be nulled');
        Assert.isNull(refreshed.DeliveryMethod__c,                         'DeliveryMethod should be nulled');
        Assert.areEqual(0, refreshed.ShippingCost__c,                           'ShippingCost should be nulled');
    }

    @IsTest
    private static void testCalculateShipping_whenPickup_returnsCostZeroAndUpdatesCDG() {
        CheckoutTestDataDTO data = arrangeCheckoutInfoData();

        Test.startTest();
        B2B_USCheckoutController.ShippingDTO result = B2B_USCheckoutController.calculateShipping(
            data.cartDeliveryGroupId, data.warehouseId, true);
        Test.stopTest();

        Assert.areEqual(0,              result.cost,        'Pickup should have zero cost');
        Assert.areEqual('USD',          result.currencyCode,    'Currency should be USD for pickup');
        Assert.areEqual('Customer pickup', result.explanation, 'Explanation should indicate pickup');
        Assert.isTrue(result.weightKg >= 0, 'Weight should be non-negative');

        CartDeliveryGroup refreshed = [SELECT DeliveryMethod__c, PorcelanosaAddress__c, ContactPointAddressId__c, ShippingCost__c FROM CartDeliveryGroup WHERE Id = :data.cartDeliveryGroupId LIMIT 1];
        Assert.areEqual('CUSTOMER-PICKUP', refreshed.DeliveryMethod__c,       'Delivery method should be CUSTOMER-PICKUP');
        Assert.areEqual(data.warehouseId,  refreshed.PorcelanosaAddress__c,   'Warehouse address should be stored in CDG');
        Assert.isNull(refreshed.ContactPointAddressId__c,                      'CPA should be nulled for pickup');
        Assert.areEqual(0,                 refreshed.ShippingCost__c,          'ShippingCost should be zero for pickup');
    }

    @IsTest
    private static void testCalculateShipping_whenShipToCustomer_returnsCalculatedCostAndUpdatesCDG() {
        CheckoutTestDataDTO data = arrangeCheckoutInfoData();

        CartDeliveryGroup cdgSetup = new CartDeliveryGroup();
        cdgSetup.Id = data.cartDeliveryGroupId;
        cdgSetup.SalesOrg__c = data.salesOrg;
        update cdgSetup;

        ContactPointAddress cpa = new ContactPointAddress(
            Name = 'Customer Address',
            ParentId = data.accountId, AddressType = 'Shipping',
            CountryCode = 'US', StateCode = 'CA',
            City = 'Los Angeles', Street = '123 Main St', PostalCode = '90001'
        );
        insert cpa;

        insert new B2BShippingRate__c(
            Store__c = 'USD_STORE', SalesOrg__c = data.salesOrg,
            CountryCode__c = 'US', StateCode__c = 'CA',
            ShippingMethod__c = 'US-UPS-60',
            Weight__c = 60, WeightUnit__c = 'lb',
            Amount__c = 55, Priority__c = 1, Active__c = true,
            CurrencyIsoCode = 'USD'
        );

        insert new B2BShippingRate__c(
            Store__c = 'USD_STORE', SalesOrg__c = data.salesOrg,
            CountryCode__c = 'US', StateCode__c = 'CA',
            ShippingMethod__c = 'US-STD',
            Weight__c = 100, WeightUnit__c = 'lb',
            Amount__c = 90, Priority__c = 1, Active__c = true,
            CurrencyIsoCode = 'USD'
        );        

        Test.startTest();
        B2B_USCheckoutController.ShippingDTO result = B2B_USCheckoutController.calculateShipping(
            data.cartDeliveryGroupId, cpa.Id, false);
        Test.stopTest();

        Assert.isTrue(result.cost > 0,        'Cost should be positive');
        Assert.areEqual('USD',  result.currencyCode,    'Currency should be USD');
        Assert.isNotNull(result.explanation,        'Explanation should describe the rate');

        CartDeliveryGroup refreshed = [SELECT DeliveryMethod__c, ContactPointAddressId__c, PorcelanosaAddress__c, ShippingCost__c FROM CartDeliveryGroup WHERE Id = :data.cartDeliveryGroupId LIMIT 1];
        Assert.areEqual('SHIP-TO-CUSTOMER', refreshed.DeliveryMethod__c,     'Delivery method should be SHIP-TO-CUSTOMER');
        Assert.areEqual(cpa.Id,             refreshed.ContactPointAddressId__c, 'CPA id should be stored in CDG');
        Assert.isNull(refreshed.PorcelanosaAddress__c,                        'Warehouse address should be nulled');
        Assert.areEqual(result.cost,        refreshed.ShippingCost__c,        'CDG ShippingCost should match the returned cost');
    }    

    private static CheckoutTestDataDTO arrangeCheckoutInfoData() {
        CheckoutTestDataDTO dto = new CheckoutTestDataDTO();

        dto.salesOrg = [
            SELECT Default_Sales_Organization__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].Default_Sales_Organization__c;
        System.assert(String.isNotBlank(dto.salesOrg), 'The test user must have Default_Sales_Organization__c informed.');

        WebCart cart = [
            SELECT Id, AccountId, SpecialInstructions__c, DeliveryDate__c
            FROM WebCart
            LIMIT 1
        ];
        dto.cartId = cart.Id;
        dto.accountId = cart.AccountId;
        cart.SpecialInstructions__c = 'PO instructions';
        cart.DeliveryDate__c = Date.newInstance(2026, 4, 15);
        update cart;

        CartDeliveryGroup deliveryGroup = [
            SELECT Id, ContactPointAddressId__c
            FROM CartDeliveryGroup
            WHERE CartId = :cart.Id
            LIMIT 1
        ];
        dto.cartDeliveryGroupId = deliveryGroup.Id;
        dto.contactPointAddressId = deliveryGroup.ContactPointAddressId__c;

        B2BMarketSettings__c market = new B2BMarketSettings__c(
            Name                    = 'TEST_US_DEALERS',
            Label__c                = 'Test US Dealers',
            CurrencyIsoCode         = 'USD',
            CountryCode__c          = 'US',
            CheckoutMode__c         = 'REGION',
            StockDisplay__c         = 'NONE',
            PalletSurchargeMode__c  = 'NOT_APPLICABLE',
            Active__c               = true
        );
        insert market;

        Sales_Org__c salesOrg = new Sales_Org__c(
            Name            = 'Test Sales Org',
            Company__c      = '610',
            SalesOrg__c     = dto.salesOrg,
            CountryCode__c  = 'US',
            CurrencyIsoCode = 'USD',
            SAP_Id__c       = dto.salesOrg,
            TaxPercent__c   = 0
        );
        insert salesOrg;

        insert new B2BAccountSettings__c(
            AccountId__c = cart.AccountId,
            StoreName__c = 'US DEALERS',
            Market__c = market.Id,
            PricingMode__c = 'LIVE',
            SalesOrgId__c = salesOrg.Id,
            CreditCardAllowed__c = false,
            CreditCardSurcharge__c = 3.5
        );

        insert new DeliveryRequirement__c(
            ContactPointAddress__c = deliveryGroup.ContactPointAddressId__c,
            Cart__c = cart.Id,
            LiftgateRequired__c = true,
            DeliveryContactName__c = 'Receiving team'
        );

        PorcelanosaAddress__c warehouse = new PorcelanosaAddress__c(
            Name = 'Ramsey Warehouse',
            SAPSalesOrg__c = dto.salesOrg,
            NBK_isActive__c = true,
            NBK_Address_Type__c = 'B2B-Warehouse;Collection Point;',
            NBK_Address__Street__s = '600 NJ-17',
            NBK_Address__City__s = 'Ramsey',
            NBK_Address__PostalCode__s = '07446',
            NBK_Address__StateCode__s = 'NJ',
            NBK_Address__CountryCode__s = 'US',
            NBK_Phone__c = '+1 201-555-0100',
            Email__c = 'ramsey@porcelanosa.com',
            CutoffTime__c = Time.newInstance(15, 30, 0, 0),
            PreparationDays__c = 2,
            TimeZone__c = 'America/New_York',
            CustomerPickupHours__c = 'Mon-Fri 08:00-17:00'
        );
        insert warehouse;
        dto.warehouseId = warehouse.Id;

        CartItem[] items = [select Id, Product2.Id, Quantity, PerUnitWeight from CartItem where CartId = :cart.Id];
        for (CartItem item : items) {
            item.PerUnitWeight = 100;
        }
        update items;   

        return dto;
    }

    private class CheckoutTestDataDTO {
        private Id cartId;
        private Id accountId;
        private Id cartDeliveryGroupId;
        private Id contactPointAddressId;
        private Id warehouseId;
        private String salesOrg;
    }
}