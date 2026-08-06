/**
 * @author         Ramón Prades
 * @date           May 2026
 * @group          B2B
 * @description    Calculates shipping rates based on weight blocks and state rules.
 *                 Applies to US shipments only. Selects UPS or Standard Shipping
 *                 depending on total shipment weight, then calculates cost in weight
 *                 blocks (rounds up total weight to nearest block).
 *                 -----------------------------------------------------
 *                 Usage: chain setters, call calculate(), then read results via getters.
 *                 Throws IllegalStateException if getters are called before calculate().
 */
public class B2B_ShippingRateByWeight {

    public static final Decimal LB_PER_KG   = 2.20462;
    public static final String  US_UPS       = 'US-UPS-60';
    public static final String  US_STD       = 'US-STD';
    public static final Integer MAX_LB_UPS   = 60;
    private static final String STORE_LABEL  = 'USD_STORE';

    // ─── Input (setters) ─────────────────────────────────────────────────────────

    private String  salesOrg;
    private String  countryCode;
    private String  stateCode;
    private Decimal weightKg;


    public B2B_ShippingRateByWeight setSalesOrg(String v)    { salesOrg    = v; return this; }
    public B2B_ShippingRateByWeight setCountryCode(String v) { countryCode = v; return this; }
    public B2B_ShippingRateByWeight setStateCode(String v)   { stateCode   = v; return this; }
    public B2B_ShippingRateByWeight setWeightKg(Decimal v)   { weightKg    = v; return this; }

    // ─── Output (getters) ────────────────────────────────────────────────────────

    private Boolean calculated   = false;
    private Decimal resultCost;
    private String  resultCurrency;
    private String  resultExplanation;
    private String  resultCarrier;
    private Boolean resultAvailable = false;

    public Decimal getCost()        { assertCalculated(); return this.resultCost; }
    public String  getCurrency()    { assertCalculated(); return this.resultCurrency; }
    public String  getExplanation() { assertCalculated(); return this.resultExplanation; }
    public String  getCarrierName() { assertCalculated(); return this.resultCarrier; }
    public Boolean getAvailable() { assertCalculated(); return this.resultAvailable; }

    private void assertCalculated() {
        if (!calculated) {
            throw new ContextException('Call calculate() before reading results');
        }
    }

    // ─── Calculation ─────────────────────────────────────────────────────────────

    /**
     * Calculates the shipping rate based on the parameters set via setters.
     * Returns this instance for fluent chaining.
     * Throws IllegalArgumentException if any required parameter is missing.
     * Throws NoRuleException if no matching active rule is found.
     */
    public B2B_ShippingRateByWeight calculate() {
        if (String.isBlank(salesOrg) || String.isBlank(countryCode) ||
            String.isBlank(stateCode) || weightKg == null || weightKg <= 0) {
            throw new IllegalArgumentException('salesOrg, countryCode, stateCode and weightKg are required');
        }

        if (countryCode != 'US') {
            throw new IllegalArgumentException('Only US shipments are supported');
        }

        Decimal totalWeightInLb = weightKg * LB_PER_KG;
        String shippingMethod = totalWeightInLb <= MAX_LB_UPS ? US_UPS : US_STD;

        B2BShippingRate__c rule = getRule(shippingMethod);
        if (rule == null) {
            this.resultAvailable   = false;
            this.resultExplanation = 'Delivery to ' + this.stateCode + ' is not available. Please contact your sales representative for assistance.';
            this.calculated        = true;
            return this;
        }        
        Decimal blockWeight = (rule.Weight__c == null || rule.Weight__c <= 0) ? 999999 : rule.Weight__c;
        Integer blocks = (Integer) Math.ceil(totalWeightInLb / blockWeight);

        this.resultAvailable   = true;
        this.resultCost        = rule.Amount__c * blocks;
        this.resultCurrency    = rule.CurrencyIsoCode;
        this.resultExplanation = formatAmount(rule.Amount__c, rule.CurrencyIsoCode)
                               + ' per each '
                               + formatNumber(rule.Weight__c)
                               + ' ' + rule.WeightUnit__c.toLowerCase();
        this.resultCarrier     = shippingMethod.equals(US_UPS) ? 'UPS Shipping' : 'Standard Shipping';
        this.resultCarrier     += ' (' + stateCode + ')';
        this.calculated = true;
        return this;
    }

    // ─── Private helpers ─────────────────────────────────────────────────────────

    private static String formatAmount(Decimal amount, String currencyCode) {
        String formatted = amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
        return currencyCode == 'USD' ? '$' + formatted : formatted + ' ' + currencyCode;
    }

    private static String formatNumber(Decimal n) {
        String s = n.stripTrailingZeros().toPlainString();
        if (s.length() > 3) {
            s = s.replaceAll('(\\d)(?=(\\d{3})+$)', '$1,');
        }
        return s;
    }

    private B2BShippingRate__c getRule(String shippingMethod) {
        List<B2BShippingRate__c> candidates = [
            SELECT Id, Weight__c, WeightUnit__c, Amount__c, CurrencyIsoCode, Priority__c
            FROM B2BShippingRate__c
            WHERE Store__c          = :STORE_LABEL
              AND SalesOrg__c       = :salesOrg
              AND CountryCode__c    = :countryCode
              AND StateCode__c      = :stateCode
              AND ShippingMethod__c = :shippingMethod
              AND Active__c         = true
            ORDER BY Priority__c ASC
            LIMIT 1
        ];
        return candidates.isEmpty() ? null : candidates[0];
    }


} // class