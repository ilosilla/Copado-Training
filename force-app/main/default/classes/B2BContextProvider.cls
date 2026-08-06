@SuppressWarnings('PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces, PMD.EmptyCatchBlock')   
/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  B2BContextProvider
 * ─────────────────────────────────────────────────────────────────────────────
 *  PURPOSE
 *  -------
 *  Single source of truth for the B2B store context.
 *
 *  The context encapsulates all account-level and market-level settings that
 *  drive market-specific behaviour across LWC components and Apex services
 *  (pricing rules, payment methods, currency, etc.).
 *
 *  USAGE
 *  -----
 *  From LWC  → call via @AuraEnabled: B2BContextProvider.getContext(accountId)
 *  From Apex → call directly:         B2BContextProvider.getContext(accountId)
 *
 *  CACHING
 *  -------
 *  The context is immutable within a session. It is cached in Platform Session
 *  Cache (partition 'local.b2bContext') keyed by accountId. Automatically
 *  invalidated on session timeout, logout, or browser close.
 *
 *  DATA MODEL
 *  ----------
 *  B2BAccountSettings__c  — one record per account; account-level settings
 *                            and lookup (Market__c) to B2BMarketSettings__c.
 *  B2BMarketSettings__c   — one record per market segment (e.g. US_DEALERS);
 *                            market-level settings shared by all accounts in
 *                            that market, plus optional lookup to
 *                            B2BPaymentSettings__c.
 *  B2BPaymentSettings__c  — payment gateway configuration. NOT cached.
 *                            Read on demand via getPaymentSettings().
 *  PorcelanosaAddress__c  — warehouse address resolved by SalesOrg; for
 *                            direct customers (no SalesOrg), a generic
 *                            Porcelanosa Grupo entry is returned instead.
 *  SAP_Plants__x          — external object; resolves SalesOrg → Plant.
 *  SAP_StockWarehouses__x — external object; resolves Plant → ZSTK Warehouses.
 *  BuyerGroupPricebook    — resolves BuyerGroup → Pricebook2.
 *
 *  DTO CONVENTION
 *  --------------
 *  Field names mirror BBDD names: remove __c, first letter lowercase.
 *  e.g. IsDirectCustomer__c → isDirectCustomer
 *
 *  @author  Ramón Prades
 *  @since   2026
 * ─────────────────────────────────────────────────────────────────────────────
 */
public without sharing class B2BContextProvider {

    public static final String CACHE_PARTITION          = 'local.b2bContext';
    public static final String DIRECT_CUSTOMER_NAME     = 'Porcelanosa Direct';
    public static final String DIRECT_CUSTOMER_ADDRESS  = '12540 Vila-real  ·  Spain';
    public static final String CHECKOUT_FACTORY         = 'FACTORY';   // CheckoutMode__c value that drives the direct/factory branch

    // Prefijo de los errores de contexto. Se lanzan como CONTEXT_ERROR:XXX, donde
    // XXX es un detalle interno (ACC…). El LWC b2bErrorPage parte por ':'
    // y usa la parte izquierda para el mensaje al cliente y la derecha como
    // referencia interna (para soporte).
    public static final String CONTEXT_ERROR = 'CONTEXT_ERROR';

    private static void raiseContextException(String detail, String description) {
        raiseContextException(detail, description, null);
    }

    /**
     * Punto único para los errores de contexto: dispara un SystemAlert
     * (severidad HIGH) y LANZA la excepción con el código CONTEXT_ERROR:XXX.
     * Un contexto irresoluble NO debería ocurrir nunca en producción.
     * setMessage garantiza que el código llega limpio al LWC y no como
     * "Script-thrown exception".
     *
     * @param detail       sufijo del código (ACC…) → forma CONTEXT_ERROR:XXX
     * @param description  qué ha fallado exactamente (para el SystemAlert)
     * @param context      datos técnicos del caso: accountId, divisas, IDs…
     */
    private static void raiseContextException(String detail, String description, Map<String, Object> context) {
        String code = CONTEXT_ERROR + ':' + detail;

        Map<String, Object> ctx = context != null ? context : new Map<String, Object>();
        ctx.put('code', code);
        ctx.put('description', description);

        new SystemAlert('B2B - CONTEXT ERROR', SystemAlert.Severity.HIGH)
            .withContext(ctx)
            .withHints(new List<String>{
                'El contexto B2B no se pudo resolver; el usuario ha sido redirigido a la página de error.',
                'No debería ocurrir en producción: revisar B2BAccountSettings__c, el Market y el Pricebook de la cuenta.',
                'La resolución del contexto está en B2BContextProvider.getContext / buildContext.'
            })
            .withDedupKey('B2B_CONTEXT_ERROR_' + detail + '_' + String.valueOf(ctx.get('accountId')))
            .notify();

        AuraHandledException e = new AuraHandledException(code);
        e.setMessage(code);
        throw e;
    }

    /* ========================================================= */
    /* PUBLIC DTOs                                               */
    /* ========================================================= */

    public class AccountSettingsDTO {
        @AuraEnabled public Boolean creditCardAllowed;
        @AuraEnabled public Decimal creditCardSurcharge;
        @AuraEnabled public String  notifyOrderTo;      // NONE | CUSTOMER | REP | BOTH
        // Pricing visibility — derived from PricingMode__c (LIVE | DEFERRED | HIDDEN)
        @AuraEnabled public Boolean showPrices;         // true only when LIVE
        @AuraEnabled public Boolean deferredPricing;    // true only when DEFERRED (prices requested from SAP at checkout)
    }

    public class MarketSettingsDTO {
        @AuraEnabled public Id      id;
        @AuraEnabled public String  name;               // internal key e.g. US_DEALERS
        @AuraEnabled public String  label;              // display label e.g. US Dealers
        @AuraEnabled public String  countryCode;        // ISO 2-letter e.g. US, IE
        @AuraEnabled public String  currencyIsoCode;
        @AuraEnabled public String  checkoutMode;       // REGION | FACTORY — drives the checkout branch
        @AuraEnabled public Boolean isDirectCustomer;    // derived: checkoutMode == FACTORY
        @AuraEnabled public Boolean validatePrices;
        @AuraEnabled public Id      paymentSettingsId;  // null if no payment gateway
        // Stock visibility — derived from StockDisplay__c (NONE | STATUS | QUANTITY)
        @AuraEnabled public Boolean showStock;          // false only when NONE
        @AuraEnabled public Boolean stockAsQuantity;    // true only when QUANTITY; false = semaphore
        // Shade (tono) feature flag
        @AuraEnabled public Boolean shadeEnabled;
        // Unit system — derived from UnitSystem__c (METRIC | IMPERIAL)
        @AuraEnabled public Boolean useMetricSystem; // false only when IMPERIAL
        // Pallet surcharge mode — derived from PalletSurchargeMode__c
        @AuraEnabled public String palletSurchargeMode; // NOT_APPLICABLE | FIXED_BASES_002
    }

    public class WarehouseDTO {
        @AuraEnabled public String name;
        @AuraEnabled public String formattedAddress;
        @AuraEnabled public String contactLine;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
    }

    public class PricingContextDTO {
        @AuraEnabled public Id           buyerGroupId;
        @AuraEnabled public Id           pricebookId;    // null when buyerGroupId is null or no BuyerGroupPricebook found
    }

    public class PlantDTO {
        @AuraEnabled public String       plant;
        @AuraEnabled public String       company;      // FI company code (Bukrs) resolved from SAP_CompanyPlants__x
        @AuraEnabled public List<String> warehouses;
    }

    public class StockContextDTO {
        @AuraEnabled public List<PlantDTO> plants;       // null when showStock=false
    }

    public class B2BContext {
        // Identity
        @AuraEnabled public Id                 effectiveAccountId;
        @AuraEnabled public String             salesOrg;    // SAP Sales Org code e.g. '603'
        @AuraEnabled public String             salesOrgName;
        @AuraEnabled public String             cacheVersion;
        // Nested settings
        @AuraEnabled public AccountSettingsDTO account;
        @AuraEnabled public MarketSettingsDTO  market;
        @AuraEnabled public WarehouseDTO       warehouse;
        @AuraEnabled public PricingContextDTO  pricing;
        @AuraEnabled public StockContextDTO    stock;
        @AuraEnabled public String             userLanguage; // LanguageLocaleKey e.g. 'en_GB', 'en_US'
        @AuraEnabled public String             userLocale;   // Locale e.g. 'es_ES', 'en_GB' — drives number/date formatting
        @AuraEnabled public String             debugText;
    }

    /* ========================================================= */
    /* PUBLIC METHODS (API)                                      */
    /* ========================================================= */

    /**
     * Returns the B2B context for the given account.
     * Reads from Session Cache if available; otherwise builds and caches it.
     *
     * @param accountId    The effective account Id (from LWC session or passed explicitly)
     * @param buyerGroupId The buyer group Id (from LWC session.buyerGroups[0].id).
     *                     Assumed 1:1 with account — one store, one buyer group per account.
     * @return             B2BContext populated with account, market and pricing settings
     */
    @AuraEnabled(cacheable=true)
    public static B2BContext getContext(Id accountId, Id buyerGroupId) {
        if (accountId == null) {
            raiseContextException('ACC', 'accountId is null');
        }

        B2BContext cached = readFromCache(accountId);
        if (cached != null) {
            return cached;
        }
        B2BAccountSettings__c settings = readAccountSettings(accountId);
        B2BContext context = buildContext(accountId, buyerGroupId, settings);
        writeToCache(accountId, context);
        return context;
    }

    /**
     * Reads the B2B context from Session Cache only — does not build/query.
     * Use this from server-side callers (e.g. other @AuraEnabled methods) that only
     * have the accountId and expect the context to already be cached for this session
     * (typically loaded earlier by libStoreContextProvider).
     *
     * @param accountId  The effective account Id
     * @return           The cached B2BContext, or null if not cached for this session
     */
    public static B2BContext getContext(Id accountId) {
        return readFromCache(accountId);
    }

    /**
     * Reads payment gateway configuration for the given settings Id.
     * NOT cached — contains sensitive data (URLs, MerchantID, Secret).
     * Call only when processing a payment, using ctx.market.paymentSettingsId.
     *
     * @param paymentSettingsId  Id from B2BContext.market.paymentSettingsId
     * @return                   B2BPaymentSettings__c or null if not found / null input
     */
    public static B2BPaymentSettings__c getPaymentSettings(Id paymentSettingsId) {
        if (paymentSettingsId == null) return null;
        List<B2BPaymentSettings__c> settings = [
            SELECT PaymentGatewayURL__c, CaptureURL__c, ResponseURL__c,
                   ErrorURL__c, RedirectTo__c, MerchantID__c, Secret__c
            FROM B2BPaymentSettings__c
            WHERE Id = :paymentSettingsId
            LIMIT 1
        ];
        return settings.isEmpty() ? null : settings[0];
    }

    // =========================================================
    // PRIVATE — CACHE
    // =========================================================

    private static B2BContext readFromCache(Id accountId) {
        try {
            return (B2BContext) Cache.Session.get(CACHE_PARTITION + '.' + cacheKey(accountId));
        } catch (Exception e) {
            return null;
        }
    }

    private static void writeToCache(Id accountId, B2BContext context) {
        try {
            Cache.Session.put(CACHE_PARTITION + '.' + cacheKey(accountId), context);
        } catch (Exception e) {
            // Cache not available — fail silently, context still returned
        }
    }

    private static String cacheKey(Id accountId) {
        return 'ctx' + String.valueOf(accountId).replace('-', '').left(15);
    }

    // =========================================================
    // PRIVATE — DATA
    // =========================================================

    private static B2BAccountSettings__c readAccountSettings(Id accountId) {
        List<B2BAccountSettings__c> settings = [
            SELECT  SalesOrgId__c,
                    SalesOrgId__r.Name,
                    SalesOrgId__r.SalesOrg__c,
                    CreditCardAllowed__c, CreditCardSurcharge__c,
                    NotifyOrderTo__c,
                    LastModifiedDate,
                    Market__c,
                    Market__r.Name,
                    Market__r.Label__c,
                    Market__r.CurrencyIsoCode,
                    Market__r.CountryCode__c,
                    Market__r.CheckoutMode__c,
                    Market__r.ValidatePrices__c,
                    Market__r.B2BPaymentSetting__c,
                    Market__r.StockDisplay__c,
                    Market__r.ShadeEnabled__c,
                    Market__r.UnitSystem__c,
                    Market__r.PalletSurchargeMode__c,
                    PricingMode__c
            FROM B2BAccountSettings__c
            WHERE AccountId__c = :accountId
            AND   Active__c    = true
            LIMIT 1
        ];
        if (settings.isEmpty()) {
            raiseContextException('ACC', 'No active B2BAccountSettings__c for account',
                new Map<String, Object>{ 'accountId' => accountId });
        }
        return settings[0];
    }

    private static B2BContext buildContext(Id accountId, Id buyerGroupId, B2BAccountSettings__c s) {
        AccountSettingsDTO acct  = new AccountSettingsDTO();
        acct.creditCardAllowed   = s.CreditCardAllowed__c;
        acct.creditCardSurcharge = s.CreditCardSurcharge__c;
        acct.notifyOrderTo       = s.NotifyOrderTo__c;
        acct.showPrices          = s.PricingMode__c == 'LIVE';
        acct.deferredPricing     = s.PricingMode__c == 'DEFERRED';

        String stockDisplay      = s.Market__r?.StockDisplay__c;
        MarketSettingsDTO mkt    = new MarketSettingsDTO();
        mkt.id                   = s.Market__c;
        mkt.name                 = s.Market__r?.Name;
        mkt.label                = s.Market__r?.Label__c;
        mkt.countryCode          = s.Market__r?.CountryCode__c;
        mkt.currencyIsoCode      = s.Market__r?.CurrencyIsoCode;
        mkt.checkoutMode         = s.Market__r?.CheckoutMode__c;
        mkt.isDirectCustomer     = mkt.checkoutMode == CHECKOUT_FACTORY;
        mkt.validatePrices       = s.Market__r?.ValidatePrices__c;
        mkt.paymentSettingsId    = s.Market__r?.B2BPaymentSetting__c;
        mkt.showStock            = stockDisplay == 'STATUS' || stockDisplay == 'QUANTITY';
        mkt.stockAsQuantity      = stockDisplay == 'QUANTITY';
        mkt.shadeEnabled         = s.Market__r?.ShadeEnabled__c == true;
        mkt.useMetricSystem      = s.Market__r?.UnitSystem__c?.toUpperCase() != 'IMPERIAL';
        mkt.palletSurchargeMode  = s.Market__r?.PalletSurchargeMode__c;

        B2BContext ctx           = new B2BContext();
        ctx.effectiveAccountId   = accountId;
        if (mkt.isDirectCustomer) {
            ctx.salesOrg         = null;
            ctx.salesOrgName     = DIRECT_CUSTOMER_NAME;
        } else {
            ctx.salesOrg         = s.SalesOrgId__r?.SalesOrg__c;
            ctx.salesOrgName     = s.SalesOrgId__r?.Name;
        }
        ctx.cacheVersion         = String.valueOf(s.LastModifiedDate.getTime());
        ctx.account              = acct;
        ctx.market               = mkt;
        ctx.warehouse            = buildWarehouse(s.SalesOrgId__r?.SalesOrg__c, mkt.isDirectCustomer);
        ctx.pricing              = buildPricingContext(buyerGroupId);
        ctx.stock                = buildStockContext(ctx.salesOrg, mkt.showStock, mkt.isDirectCustomer);
        ctx.userLanguage         = UserInfo.getLanguage();
        ctx.userLocale           = UserInfo.getLocale();

        return ctx;
    }

    /**
     * Resolves the warehouse for display purposes (footer, etc.).
     * - Regular accounts: resolves from PorcelanosaAddress__c by SalesOrg.
     * - Direct customers (no SalesOrg): returns a generic Porcelanosa Grupo entry
     *   without contact details since there are multiple factory locations.
     */
    private static WarehouseDTO buildWarehouse(String salesOrg, Boolean isDirectCustomer) {
        if (isDirectCustomer == true) {
            WarehouseDTO wh     = new WarehouseDTO();
            wh.name             = DIRECT_CUSTOMER_NAME;
            wh.formattedAddress = DIRECT_CUSTOMER_ADDRESS;
            wh.contactLine      = null;
            return wh;
        }

        if (String.isBlank(salesOrg)) {
            return null;
        }

        List<PorcelanosaAddress__c> pors = [
            SELECT Name, NBK_Address__c, NBK_Phone__c, Email__c, NBK_SAPId__c
            FROM PorcelanosaAddress__c
            WHERE SAPSalesOrg__c          = :salesOrg
            AND   NBK_isActive__c         = true
            AND   NBK_Address_Type__c INCLUDES ('B2B-Warehouse')
            LIMIT 1
        ];
        if (pors.isEmpty()) {
            return null;
        }

        PorcelanosaAddress__c p = pors[0];
        AddressDTO addr         = AddressDTO.readPorcelanosaAddress(p);
        WarehouseDTO wh         = new WarehouseDTO();
        wh.name                 = p.Name;
        wh.formattedAddress     = new AddressFormatter(addr).excludeCountryName().formatAsString();
        wh.contactLine          = buildContactLine(p.NBK_Phone__c, p.Email__c);
        wh.phone                = String.isBlank(p.NBK_Phone__c) ? null : p.NBK_Phone__c.trim();
        wh.email                = String.isBlank(p.Email__c)     ? null : p.Email__c.trim();
        return wh;
    }

    @TestVisible
    private static String buildContactLine(String phone, String email) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(phone)) parts.add(phone);
        if (String.isNotBlank(email)) parts.add(email);
        return parts.isEmpty() ? null : String.join(parts, ' · ');
    }

    /**
     * Resolves the pricing context (pricebook).
     * Always resolved when buyerGroupId is available — pricebook entries carry product
     * metadata (pcsPerBox, boxPerPal) required for stock status calculation regardless
     * of whether prices are shown to the user.
     */
    private static PricingContextDTO buildPricingContext(Id buyerGroupId) {
        PricingContextDTO pricing = new PricingContextDTO();
        pricing.buyerGroupId = buyerGroupId;

        if (buyerGroupId != null) {
            List<BuyerGroupPricebook> bgpbs = [
                SELECT Pricebook2Id
                FROM BuyerGroupPricebook
                WHERE BuyerGroupId = :buyerGroupId
                LIMIT 1
            ];
            pricing.pricebookId = bgpbs.isEmpty() ? null : bgpbs[0].Pricebook2Id;
        }

        return pricing;
    }

    /**
     * Resolves the stock context (plants and their ZSTK warehouses).
     * - Regular accounts: one plant resolved from salesOrg via SAP_Plants__x.
     * - Direct customers: all factory plants (Plant__c <= '010'), each with their warehouses.
     * - Returns null when showStock is false.
     *
     * Warehouses are resolved in a single IN query to avoid N+1 calls to the external object.
     */
    private static StockContextDTO buildStockContext(String salesOrg, Boolean showStock, Boolean isDirectCustomer) {
        if (showStock != true) return null;

        List<SAP_Plants__x> plantRecs;
        if (isDirectCustomer == true) {
            plantRecs = [
                SELECT Plant__c
                FROM SAP_Plants__x
                WHERE Plant__c <= '010'
            ];
        } else if (String.isNotBlank(salesOrg)) {
            plantRecs = [
                SELECT Plant__c
                FROM SAP_Plants__x
                WHERE Vkorg__c = :salesOrg
                LIMIT 1
            ];
        }

        if (plantRecs == null || plantRecs.isEmpty()) return null;

        // Collect plant codes and resolve all warehouses in one query
        List<String> plantCodes = new List<String>();
        for (SAP_Plants__x p : plantRecs) {
            if (String.isNotBlank(p.Plant__c)) plantCodes.add(p.Plant__c);
        }
        if (plantCodes.isEmpty()) return null;

        List<SAP_StockWarehouses__x> whRecs = [
            SELECT Plant__c, Warehouse__c
            FROM SAP_StockWarehouses__x
            WHERE Plant__c IN :plantCodes
            AND   IsZSTK__c = true
        ];

        // Resolve the FI company code (Bukrs) per plant
        Map<String, String> companyByPlant = new Map<String, String>();
        for (SAP_CompanyPlants__x cp : [
            SELECT Plant__c, Company__c
            FROM SAP_CompanyPlants__x
            WHERE Plant__c IN :plantCodes
        ]) {
            if (String.isNotBlank(cp.Plant__c)) companyByPlant.put(cp.Plant__c, cp.Company__c);
        }

        return buildStockFromData(plantCodes, whRecs, companyByPlant);
    }

    @TestVisible
    private static StockContextDTO buildStockFromData(List<String> plantCodes, List<SAP_StockWarehouses__x> whRecs, Map<String, String> companyByPlant) {
        // Group warehouses by plant
        Map<String, List<String>> whsByPlant = new Map<String, List<String>>();
        for (SAP_StockWarehouses__x w : whRecs) {
            if (String.isBlank(w.Warehouse__c)) continue;
            if (!whsByPlant.containsKey(w.Plant__c)) {
                whsByPlant.put(w.Plant__c, new List<String>());
            }
            whsByPlant.get(w.Plant__c).add(w.Warehouse__c);
        }

        // Build DTO
        StockContextDTO stock = new StockContextDTO();
        stock.plants = new List<PlantDTO>();
        for (String plantCode : plantCodes) {
            List<String> whs = whsByPlant.get(plantCode);
            if (whs == null || whs.isEmpty()) continue;
            PlantDTO dto   = new PlantDTO();
            dto.plant      = plantCode;
            dto.company    = companyByPlant?.get(plantCode);
            dto.warehouses = whs;
            stock.plants.add(dto);
        }

        return stock.plants.isEmpty() ? null : stock;
    }
}