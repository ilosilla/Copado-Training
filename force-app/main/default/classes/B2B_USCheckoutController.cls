/**
 * B2B_USCheckoutController.cls
 * 
 * Controller class for B2B US Checkout processes.
 */
public without sharing class B2B_USCheckoutController {

    private static final String WAREHOUSE_FIELDS =
        'Id, Name, NBK_Address__c, NBK_Phone__c, Email__c, NBK_SAPId__c, ' +
        'CutoffTime__c, PreparationDays__c, TimeZone__c, CustomerPickupHours__c';

    /**
     * Returns:
     * - the list of available contact point addresses of an account 
     * - the Id of the selected contactPointAddress
     */
    @AuraEnabled(cacheable=false) 
    public static CheckoutInfoDTO getCheckoutInfo(String cartId, String accountId, String cartDeliveryGroupId) {
        CheckoutInfoDTO dto = new CheckoutInfoDTO();
        User u = [SELECT Default_Sales_Organization__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        dto.salesOrg = u.Default_Sales_Organization__c;
        dto.deliveryAddresses = new List<AddressDTO>();
        dto.deliveryRequirementsMap = new Map<Id, DeliveryRequirement__c>();
        if (String.isNotBlank(accountId)) {
            Account buyerAccount = [SELECT Id, Owner.Name, Owner.Email FROM Account WHERE Id = :accountId LIMIT 1];
            dto.salesRepName = buyerAccount.Owner.Name;
            dto.salesRepEmail = buyerAccount.Owner.Email;

            ContactPointAddress[] deliveryAddresses = [
                SELECT
                    Id, Name, Address, Phone__c, Mobile__c, Email__c, SAPId__c, LastModifiedDate, IsDefault
                FROM ContactPointAddress
                WHERE
                    ParentId = :accountId and  AddressType = 'Shipping'
                    and IsDeleted = false and Disabled__c = false
                ORDER BY IsDefault DESC, LastModifiedDate DESC
            ];

            // Add the account's own (nominal) address as the first delivery option, always available:
            // SAP ships to the customer's header address when no separate ship-to address is set up.
            // It's the default selection only when none of the account's real addresses is already marked default
            // (replaces the previous behaviour of auto-promoting the most recently modified address to default).
            Boolean hasRealDefaultAddress = !deliveryAddresses.isEmpty() && deliveryAddresses[0].IsDefault;
            AddressDTO accountAddress = AddressDTO.readFromAccount(accountId);
            accountAddress.addressType = 'Shipping';
            accountAddress.isDefault = !hasRealDefaultAddress;
            dto.deliveryAddresses.add(accountAddress);

            Set<Id> contactPointAddressIds = new Set<Id>();
            for (ContactPointAddress cpa : deliveryAddresses) {
                contactPointAddressIds.add(cpa.Id);
                AddressDTO addr = AddressDTO.readContactPointAddress(cpa);
                addr.addressType = 'Shipping';
                dto.deliveryAddresses.add(addr);
            }
            dto.deliveryRequirementsMap = getDeliveryRequirementsMap(cartId, accountId, contactPointAddressIds);
            B2BAccountSettings__c[] settings  = [
                select Id, CreditCardAllowed__c, CreditCardSurcharge__c
                from B2BAccountSettings__c
                where AccountId__c = :accountId and StoreName__c = 'US DEALERS'];
            if (settings.size() > 0) {
                dto.accountSettings = settings[0];
            } else {
                dto.accountSettings = new B2BAccountSettings__c(CreditCardAllowed__c=true, CreditCardSurcharge__c=0);
            }
        }
        if (cartId != null) {
            // Read custom fields from webcart
            WebCart cart = [SELECT Id, SpecialInstructions__c, DeliveryDate__c FROM WebCart WHERE Id = :cartId LIMIT 1];
            dto.desiredDeliveryDate = cart.DeliveryDate__c;
            dto.specialInstructions = cart.SpecialInstructions__c;
        }

        PorcelanosaAddress__c por = resolveWarehouseAddress(dto.warehouseAddressId, dto.salesOrg);
        if (por == null) {
            throw new AuraHandledException('Pickup not available: no warehouse configured for sales organization ' + dto.salesOrg);  
        }       

        // Convert to CPA because LWC expects CPA format
        dto.warehouseAddress = AddressDTO.readPorcelanosaAddress(por);
        dto.warehouseAddress.addressType = 'Warehouse';
        dto.warehouseLogistics = getWarehouseLogistics(por);
        if (dto.warehouseLogistics.customerPickupHours != null) {
            dto.warehouseAddress.additionalInfo = dto.warehouseLogistics.customerPickupHours;
        }
        return dto;
    }

    /**
     * Saves the customer reference to the cart's po number
     */
    @AuraEnabled public static void saveCartData(String cartId, String customerReference) {
        if (String.isBlank(cartId)) {
            throw new AuraHandledException('Cart Id is required');
        }
        WebCart c = [SELECT Id, PONumber FROM WebCart WHERE Id = :cartId LIMIT 1];
        if (c == null) {
            throw new AuraHandledException('Cart not found for Id ' + cartId);
        }
        c.PONumber = customerReference;
        update c;        
    }

    /**
     * Saves the delivery requirement for a given contact point address and cart (if provided)
     */
    @AuraEnabled
    public static DeliveryRequirement__c saveDeliveryRequirement(DeliveryRequirement__c deliveryRequirement, String instructions, Date deliveryDate) {  
        upsert deliveryRequirement;

        WebCart cart = new WebCart();
        cart.Id = deliveryRequirement.Cart__c;
        cart.SpecialInstructions__c = instructions;
        cart.DeliveryDate__c = deliveryDate;
        update cart;

        return deliveryRequirement;
    }

    /**
     * Gets the credit status of the buyer account from SAP
     */
    @AuraEnabled(cacheable=false) public static SAPCreditControlService.CreditResultDTO retrieveCreditStatus(String accountId) {
        if (String.isBlank(accountId)) {
            throw new AuraHandledException('Account Id is required');
        }
        User u = [SELECT Default_Sales_Organization__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        SAPCreditControlService.CreditResultDTO result;
        try {
            result = SAPCreditControlService.retrieveCreditStatus(accountId, u.Default_Sales_Organization__c);
        } catch (HttpException hex) {
            throw new AuraHandledException('Error retrieving credit status: ' + hex.getMessage());
        }
        return result;
    }

    /**
     * Validates the prices in the cart by checking the current prices from SAP
     * (Simulates an order for price validation purposes)
     */
    @AuraEnabled
    public static B2B_CommerceOrdersService.PriceValidationResultDTO validatePrices(Id webstoreId, Id cartId, Id accountId) {    
        PORSAStoreSettings__c settings = B2B_CommerceUtils.resolveStoreSettings();  
        if (settings.EnableSAPPriceValidation__c) {  
            return B2B_CommerceOrdersService.validatePricesFromCart(webstoreId, cartId, accountId);
        } else {
            B2B_CommerceOrdersService.PriceValidationResultDTO result = new B2B_CommerceOrdersService.PriceValidationResultDTO();
            result.isOk = true;
            return result;
        }
    }

    /**
    * Calculates the shipping cost for the selected delivery address.
    * Writes the result to the CartDeliveryGroup custom fields for the CartExtension
    * applicator to read. Returns a ShippingDTO for immediate display in the LWC
    * without waiting for the CartExtension pipeline to complete.
    *
    * @param cdgId     Id of the CartDeliveryGroup
    * @param addressId Id of the selected ContactPointAddress (ship-to) or PorcelanosaAddress (pickup)
    * @param isPickup  True if the customer is picking up at the warehouse
    * @return          ShippingDTO with all fields populated
    */
    @AuraEnabled
    public static ShippingDTO calculateShipping(String cdgId, String addressId, Boolean isPickup) {


        CartDeliveryGroup cdgData = [SELECT CartId, SalesOrg__c FROM CartDeliveryGroup WHERE Id = :cdgId LIMIT 1];
        Decimal weightKg = PB2B_CartCommons.getCartWeightKg(cdgData.CartId);
        WebCart cart = [SELECT AccountId FROM WebCart WHERE Id = :cdgData.CartId LIMIT 1];
        Boolean isAccountAddress = (addressId == cart.AccountId);

        CartDeliveryGroup cdg = new CartDeliveryGroup();
        cdg.Id = cdgId;

        ShippingDTO result = new ShippingDTO();
        result.weightKg = weightKg;

        if (isPickup) {
            cdg.ContactPointAddressId__c = null;
            cdg.PorcelanosaAddress__c    = addressId;
            cdg.DeliveryMethod__c        = 'CUSTOMER-PICKUP';
            cdg.ShippingCost__c          = 0;
            cdg.CarrierName__c           = 'Pickup at warehouse';
            cdg.ShippingPending__c       = true;
            result.cost        = 0;
            result.currencyCode    = 'USD';
            result.explanation = 'Customer pickup';
            result.carrierName = 'Pickup at warehouse';
            result.available = true;
            update cdg;
        } else {
            String countryCode;
            String stateCode;
            if (isAccountAddress) {
                // Account's own (nominal) address — not a real ContactPointAddress, read country/state from the Account itself.
                Account acc = [SELECT BillingCountryCode, BillingStateCode FROM Account WHERE Id = :addressId LIMIT 1];
                countryCode = acc.BillingCountryCode;
                stateCode   = acc.BillingStateCode;
            } else {
                ContactPointAddress cpa = [SELECT CountryCode, StateCode FROM ContactPointAddress WHERE Id = :addressId LIMIT 1];
                countryCode = cpa.CountryCode;
                stateCode   = cpa.StateCode;
            }
            B2B_ShippingRateByWeight calc = new B2B_ShippingRateByWeight()
                .setSalesOrg(cdgData.SalesOrg__c)
                .setCountryCode(countryCode)
                .setStateCode(stateCode)
                .setWeightKg(weightKg)
                .calculate();
            if (calc.getAvailable()) {
                cdg.ContactPointAddressId__c = isAccountAddress ? null : addressId;
                cdg.PorcelanosaAddress__c    = null;
                cdg.DeliveryMethod__c        = 'SHIP-TO-CUSTOMER';
                cdg.ShippingCost__c          = calc.getCost();
                cdg.CarrierName__c           = calc.getCarrierName();
            } else {
                cdg.ContactPointAddressId__c = null;
                cdg.PorcelanosaAddress__c    = null;
                cdg.DeliveryMethod__c        = null;
                cdg.ShippingCost__c          = 0;
            }
            result.available             = calc.getAvailable();
            result.cost                  = calc.getCost();
            result.currencyCode          = calc.getCurrency();
            result.explanation           = calc.getExplanation();
            result.carrierName           = calc.getCarrierName();
            cdg.ShippingPending__c       = true;
            update cdg;
        }
        return result;
    }

    /**
     * Prepares the cart delivery group for a new shipping calculation.
     * Called when the checkout starts or when the user returns to the delivery step.
     * Resets any previously selected address and cost, stores the current user's
     * sales organization, and returns the total cart weight for display purposes.
     *
     * @param cdgId  Id of the CartDeliveryGroup to prepare
     * @return       ShippingDTO with weightKg populated; cost and explanation are null at this stage
     */
    @AuraEnabled    
    public static ShippingDTO prepareShipping(String cdgId) {
        CartDeliveryGroup cdgData = [SELECT CartId FROM CartDeliveryGroup WHERE Id = :cdgId LIMIT 1];
        User u = [SELECT Default_Sales_Organization__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        CartDeliveryGroup cdg = new CartDeliveryGroup();
        cdg.Id = cdgId;
        cdg.SalesOrg__c                 = u.Default_Sales_Organization__c;
        cdg.ContactPointAddressId__c    = null;
        cdg.PorcelanosaAddress__c       = null;
        cdg.DeliveryMethod__c           = null;
        cdg.ShippingCost__c             = 0;
        cdg.SelectedDeliveryMethodId    = null;
        cdg.ShippingPending__c          = false;
        update cdg;

        ShippingDTO result = new ShippingDTO();
        result.weightKg = PB2B_CartCommons.getCartWeightKg(cdgData.CartId);
        return result;
    }

    /* ------------------------------ PRIVATE METHODS ------------------------------ */
    /**
     * Reads the warehouse address based on the provided warehouseAddressId or salesOrg. If warehouseAddressId is provided, it takes priority. Otherwise, it falls back to finding a warehouse address for the given salesOrg. Returns null if no warehouse address is found.
     */
    private static PorcelanosaAddress__c resolveWarehouseAddress(Id warehouseAddressId, String salesOrg) {        
        String soql = 'SELECT ' + WAREHOUSE_FIELDS +
            ' FROM PorcelanosaAddress__c ' +
            ' WHERE NBK_isActive__c = true';
        if (warehouseAddressId != null) {
            soql += ' AND Id = \'' + String.escapeSingleQuotes(warehouseAddressId) + '\' ';
        } else {
            soql += ' AND NBK_Address_Type__c INCLUDES (\'B2B-Warehouse\') AND SAPSalesOrg__c = \'' + String.escapeSingleQuotes(salesOrg) + '\'';
        }
        List<PorcelanosaAddress__c> results = Database.query(soql);
        return results.isEmpty() ? null : results[0];
    }

    /**
     * Reads the delivery requirements for the given contact point addresses and cart, and returns a map of contactPointAddressId to delivery requirement.
     * Requirements saved against the account's own (nominal) address have ContactPointAddress__c = null and are keyed under accountId instead.
     */
    private static Map<Id, DeliveryRequirement__c> getDeliveryRequirementsMap(Id cartId, Id accountId, Set<Id> contactPointAddressIds) {
        List<DeliveryRequirement__c> drList = [
            SELECT
                Id,
                ContactPointAddress__c,
                Cart__c,
                Order__c,
                LiftgateRequired__c,
                InsideDelivery__c,
                AppointmentRequired__c,
                PreCallRequired__c,
                LimitedAccess__c,
                LoadingDockOnSite__c,
                ForkliftAvailableOnSite__c,
                SiteType__c,
                BuildingType__c,
                LastModifiedDate,
                DeliveryContactPhone__c,
                DeliveryContactEmail__c,
                DeliveryContactName__c
            FROM DeliveryRequirement__c
            WHERE (
                ContactPointAddress__c IN :contactPointAddressIds
                AND (Cart__c = :cartId OR Cart__c = null)
            )
            OR (
                ContactPointAddress__c = null
                AND Cart__c = :cartId
            )
            ORDER BY
                ContactPointAddress__c,
                Cart__c DESC,
                LastModifiedDate DESC
        ];

        Map<Id, DeliveryRequirement__c> drByCpa = new Map<Id, DeliveryRequirement__c>();
        for (DeliveryRequirement__c dr : drList) {
            Id key = dr.ContactPointAddress__c == null ? accountId : dr.ContactPointAddress__c;
            if (!drByCpa.containsKey(key)) {
                drByCpa.put(key, dr);
            }
        }
        return drByCpa;
    }

    private static WarehouseLogisticsDTO getWarehouseLogistics(PorcelanosaAddress__c por) {
        WarehouseLogisticsDTO logistics = new WarehouseLogisticsDTO();
        logistics.preparationDays = (Integer) por.PreparationDays__c;
        if (por.CutoffTime__c != null) {
            logistics.cutoffTimeMinutes = por.CutoffTime__c.hour() * 60 + por.CutoffTime__c.minute();
            Datetime dt = Datetime.newInstance(Date.today(), por.CutoffTime__c);
            logistics.cutoffTimeLabel = dt.format('hh:mm a');
        } else {
            logistics.cutoffTimeMinutes = 0;
            logistics.cutoffTimeLabel = null;
        }
        logistics.timeZone = por.TimeZone__c;
        logistics.customerPickupHours = por.CustomerPickupHours__c;
        logistics.preparationTimeMessage = buildPreparationTimeMessage(logistics);

        return logistics;
    }

    private static String buildPreparationTimeMessage(WarehouseLogisticsDTO logistics) {
        if (logistics == null || logistics.preparationDays == null || logistics.preparationDays <= 0) {
            return null;
        }

        Integer baseDays = logistics.preparationDays;

        // No cutoff configured → keep it simple
        if (logistics.cutoffTimeMinutes == null || logistics.cutoffTimeMinutes <= 0 || String.isBlank(logistics.cutoffTimeLabel)) {
            if (baseDays == 1) {
                return 'Ready in 1 business day.';
            }
            return 'Ready in ' + String.valueOf(baseDays) + ' business days.';
        }

        Integer maxDays = baseDays + 1;
        return 'Ready in ' + String.valueOf(baseDays) + '–' + String.valueOf(maxDays) + ' business days (cutoff ' + logistics.cutoffTimeLabel + ' local time).';
    }

    /* ------------------------------ DTO CLASSES ------------------------------ */
    
    public class CheckoutInfoDTO {
        @AuraEnabled public List<AddressDTO> deliveryAddresses;
        @AuraEnabled public AddressDTO warehouseAddress;
        @AuraEnabled public Map<Id, DeliveryRequirement__c> deliveryRequirementsMap;
        @AuraEnabled public String contactPointAddressId;
        @AuraEnabled public String warehouseAddressId;
        @AuraEnabled public String salesOrg;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String salesRepName;
        @AuraEnabled public String salesRepEmail;  
        @AuraEnabled public B2BAccountSettings__c accountSettings;
        @AuraEnabled public WarehouseLogisticsDTO warehouseLogistics {get; set;}
        @AuraEnabled public Datetime desiredDeliveryDate;
        @AuraEnabled public String specialInstructions;
    }

    public class WarehouseLogisticsDTO {
        @AuraEnabled public Integer preparationDays;
        @AuraEnabled public Integer cutoffTimeMinutes;
        @AuraEnabled public String cutoffTimeLabel;
        @AuraEnabled public String timeZone;              // IANA
        @AuraEnabled public String customerPickupHours;   // Texto informativo
        @AUraENabled public String preparationTimeMessage; // Texto informativo construido a partir de los otros campos
    }

    public class DeliveryAddressDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String state;
        @AuraEnabled public String country;
        @AuraEnabled public String countryCode;
        @AuraEnabled public String SAPId;
        @AuraEnabled public Boolean isDefault;
    }

    public class ShippingDTO {
        @AuraEnabled public Boolean available;
        @AuraEnabled public Decimal weightKg;
        @AuraEnabled public Decimal cost;
        @AuraEnabled public String  currencyCode;
        @AuraEnabled public String  explanation;        
        @AuraEnabled public String  carrierName;
    }
}