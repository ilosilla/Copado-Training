public without sharing class B2B_PaymentGatewayRedirectHelper {

    private static final String STORE_SETTING_KEY = 'US_DEALERS';

    public ConnectApi.CartSummary cart {get; private set;}
    public List<ConnectApi.CartItem> cartItems {get; private set;}
    public String token {get; private set;}

    private PORSAStoreSettings__c storeSettings;
    private String uniqueId;
    private String salesOrg;
    private String poNumber;
    private PorcelanosaAddress__c warehouse;
    private Decimal cartTotal = 0;
    private Decimal cardSurcharge = 0;    
    private Map<String, String> unitsMap;

    public B2B_PaymentGatewayRedirectHelper(B2B_CommerceCartAdapter.CommerceCartData cartData) {
        PORSAStoreSettings__c cfg = PORSAStoreSettings__c.getInstance(STORE_SETTING_KEY);
        if (cfg == null || String.isBlank(cfg.PaymentGatewayURL__c) 
            || String.isBlank(cfg.MerchantID__c) || String.isBlank(cfg.Secret__c)
            || String.isBlank(cfg.CaptureURL__c)) {
            throw new ContextException('Missing gateway configuration in store settings ' + STORE_SETTING_KEY);
        }
        this.storeSettings = cfg;

        // Validate the cart details and validate status
        if (cartData == null || cartData.cart == null) {
            throw new ObjectNotFoundException('Cart not found or empty.');
        }
        if (cartData.cart.status != ConnectApi.CartStatus.CHECKOUT) {
            throw new ContextException('Cart is not in checkout status. Current status: ' + cartData.cart.status);
        }
        this.cart = cartData.cart;
        this.cartItems = cartData.cartItems;

        User currentUser = [SELECT Id, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c from User WHERE Id = :UserInfo.getUserId() limit 1];
        this.salesOrg = currentUser.Default_Sales_Organization__c;
        this.warehouse = new B2B_CommerceUtils().getB2BWarehouse(this.salesOrg); 
        this.unitsMap =  PicklistCommons.getValues(CartItem.SalesPriceUnit__c);
    }

    public void setUniqueId(String uniqueId) {
        this.uniqueId = uniqueId;
    }

    public void setCardSurcharge(Decimal cardSurcharge) {
        this.cardSurcharge = cardSurcharge;
    }

    public void setCartTotal(Decimal cartTotal) {
        this.cartTotal = cartTotal;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public void setPoNumber(String poNumber) {
        this.poNumber = poNumber;
    }

    public Map<String, String> getFieldsPayload() {
        Map<String, String> fields = new Map<String, String>();
        this.buildConfigFields(fields);
        this.buildCustomerFields(fields);
        this.buildCartFields(fields);
        this.addSignature(fields);
        return fields;
    }

    public String getRedirectURL() {
        return this.storeSettings.PaymentGatewayURL__c;
    }


    /* ==================================================================== */

    @SuppressWarnings('PMD.UnusedLocalVariable')

    private void buildConfigFields( Map<String, String> fields) {
        String company = OrganizationUtil.getSalesOrgCompany(this.salesOrg);
        String tstamp = '';
        try {
            tstamp = DateTime.now().format('yyyyMMddHHmmss', this.warehouse.TimeZone__c);
        } catch (Exception e) {
            tstamp = DateTime.now().format('yyyyMMddHHmmss');
        }
        
        fields.put('MERCHANT', this.storeSettings.MerchantID__c);
        fields.put('B2B', '1');
        fields.put('TYPE', 'redirect_form');
        fields.put('LANG', 'en-us');
        fields.put('CAPTURE_URL_OVERRIDE', this.storeSettings.CaptureURL__c);
        fields.put('SALES_ORGANIZATION', this.salesOrg);
        fields.put('SOCIETY', company); 
        fields.put('TIMESTAMP', tstamp);
        fields.put('CUSTOM_FIELD1', this.token);

        if (String.isNotBlank(this.storeSettings.ResponseURL__c)) {
            fields.put('RESPONSE_URL_OVERRIDE', this.storeSettings.ResponseURL__c);
        }

        if (String.isNotBlank(this.storeSettings.ErrorURL__c)) {
            fields.put('ERROR_URL_OVERRIDE', this.storeSettings.ErrorURL__c);
        }

    }        
    
    private void buildCustomerFields(Map<String, String> fields) {
        Account acc = new AccountsSelector().selectById(this.cart.accountId);
        if (String.isBlank(acc.BillingStreet) || String.isBlank(acc.BillingCity) || String.isBlank(acc.BillingState)
            || String.isBlank(acc.BillingPostalCode) || String.isBlank(acc.BillingCountry)) {
            throw new AuraHandledException('Account billing address is incomplete.');
        }
        
        fields.put('CUSTOMER_ID', acc.Id);
        fields.put('CUSTOMER_NAME', UserInfo.getName());
        fields.put('CUSTOMER_SURNAME', acc.Name);
        fields.put('CUSTOMER_MAIL', UserInfo.getUserEmail());
        fields.put('CUSTOMER_PHONENUMBER_MOBILE', acc.Phone);
        fields.put('BILLING_STREET', acc.BillingStreet);
        fields.put('BILLING_CITY', acc.BillingCity);
        fields.put('BILLING_STATE', acc.BillingStateCode);
        fields.put('BILLING_POSTALCODE', acc.BillingPostalCode);
        fields.put('BILLING_COUNTRY', acc.BillingCountryCode);
    }

    public void buildCartFields(Map<String, String> fields) { 
        String quoteId = this.uniqueId ?? this.cart.cartId;       
        fields.put('CURRENCY', this.cart.currencyIsoCode);
        fields.put('AMOUNT', String.valueOf(Integer.valueOf(this.getCartTotal() * 100))); // Convert to minor units
        fields.put('QUOTE_ID', quoteId);
        fields.put('ITEM_LINE_COUNT', String.valueOf(this.cartItems.size()));
        Integer lineNum = 1;
        for (ConnectApi.CartItem item : this.cartItems) {
            String unit = 'UN'; // Default unit
            if (item.customFields != null && item.customFields.size() > 0) {
                CartItem custom = (CartItem) item.customFields[0];                
                unit = custom?.SalesPriceUnit__c ?? 'UN';
                if (unitsMap.containsKey(unit)) {
                    unit = unitsMap.get(unit);
                }   
            }
            fields.put('ITEM_' + lineNum + '_POSITION', String.valueOf(lineNum));
            fields.put('ITEM_' + lineNum + '_SKU', item.productDetails.sku);
            fields.put('ITEM_' + lineNum + '_DESCRIPTION', item.name);
            fields.put('ITEM_' + lineNum + '_QUANTITY', String.valueOf(item.quantity)); 
            fields.put('ITEM_' + lineNum + '_UNIT', unit);
            lineNum++;   
        }
    }

    /**
     * Add signature field to the payload based on the specified signed field names and the secret from store settings.
     * (HMAC SHA256 Base64)
     */
    private void addSignature(Map<String, String> fields) {

        List<String> signed = new List<String>(fields.keySet());

        if (!signed.contains('SIGNED_FIELD_NAMES')) {
            signed.add('SIGNED_FIELD_NAMES');
        }

        String signedFieldNamesValue = String.join(signed, ',');
        fields.put('SIGNED_FIELD_NAMES', signedFieldNamesValue);

        // Build data-to-sign in the exact order: key=value,key=value,...
        List<String> parts = new List<String>();
        for (String key : signed) {
            parts.add(key + '=' + (fields.containsKey(key) && fields.get(key) != null ? fields.get(key) : ''));
        }
        String dataToSign = String.join(parts, ',');

        // HMAC-SHA256 + Base64
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(dataToSign), Blob.valueOf(this.storeSettings.Secret__c));
        fields.put('SIGNATURE', EncodingUtil.base64Encode(mac));
    }

    private Decimal getCartTotal() {
        Decimal amount = 0;
        if (this.cartTotal != null && this.cartTotal > 0) {
            amount = this.cartTotal;
        } else {
            amount = Decimal.valueOf(this.cart.grandTotalAmount) + this.cardSurcharge;
        }
        return amount;
    }

    private List<String> addItemSignedFields(List<String> signed, Integer itemLineCount) {
        // OJO: índice empieza en 1
        for (Integer i = 1; i <= itemLineCount; i++) {
            signed.add('ITEM_' + i + '_POSITION');
            signed.add('ITEM_' + i + '_SKU');
            signed.add('ITEM_' + i + '_QUANTITY');
        }
        return signed;
    }

}