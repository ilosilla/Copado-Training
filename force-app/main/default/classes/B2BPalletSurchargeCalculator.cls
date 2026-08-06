/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  B2BPalletSurchargeCalculator
 * ─────────────────────────────────────────────────────────────────────────────
 *  Centralises pallet surcharge calculation logic.
 *  Reads the surcharge rate and product hierarchy prefix from ZSFDesPalet__x
 *  (external object) filtered by country + company + distribution channel.
 *  A product qualifies if its Jerarquia__c starts with the hierarchy prefix
 *  stored in the surcharge record.
 *
 *  Usage:
 *    B2BPalletSurchargeCalculator calc = new B2BPalletSurchargeCalculator(
 *        ctx.market.palletSurchargeMode, ctx);
 *    Decimal pct = calc.getSurcharge(productId); // returns rate % or 0
 *
 *  See: ADR - Pallet surcharge · ADR - Pallet surcharge display
 *  @author  Ramón Prades
 *  @since   2026
 * 
 * ─────────────────────────────────────────────────────────────────────────────
 */
public without sharing class B2BPalletSurchargeCalculator {

    private static final String SAP_COMPANY_002      = '002';
    private static final String DCHANNEL_10          = '10';
    private static final String CURRENCY_PERCENT     = '%';
    private static final String MODE_FIXED_BASES_002 = 'FIXED_BASES_002';

    private Decimal surchargeRate     = 0;
    private String  productHierarchy;

    /* ========================================================= */
    /* CONSTRUCTORS                                               */
    /* ========================================================= */

    /**
     * Production constructor. Queries ZSFDesPalet__x using the country from ctx.
     * If palletSurchargeMode is NOT_APPLICABLE (or anything other than a known mode),
     * no query is made and getSurcharge always returns 0.
     */
    public B2BPalletSurchargeCalculator(String palletSurchargeMode, B2BContextProvider.B2BContext ctx) {
        if (palletSurchargeMode != MODE_FIXED_BASES_002) { return; }

        List<ZSFDesPalet__x> rows = [
            SELECT ConditionRate__c, CurrencyCode__c, ProductHierarchy__c
            FROM   ZSFDesPalet__x
            WHERE  Country__c  = :ctx.market.countryCode
            AND    Company__c  = :SAP_COMPANY_002
            AND    DChannel__c = :DCHANNEL_10
            LIMIT  1
        ];
        if (rows.isEmpty()) { return; }
        applyRate(rows[0]);
    }

    /**
     * Test constructor — bypasses the external object query.
     * Accepts a pre-built ZSFDesPalet__x record (in-memory).
     */
    @TestVisible
    private B2BPalletSurchargeCalculator(ZSFDesPalet__x row) {
        applyRate(row);
    }

    /* ========================================================= */
    /* PUBLIC API                                                 */
    /* ========================================================= */

    /**
     * Returns the surcharge rate (%) for the given product, or 0 if no surcharge applies.
     * If productHierarchy is set, checks Jerarquia__c.startsWith(productHierarchy).
     * If productHierarchy is blank, falls back to IsTile__c && !IsSpecialTile__c.
     */
    public Decimal getSurcharge(Id productId) {
        if (surchargeRate == 0) { return 0; }
        List<Product2> prods = [
            SELECT Jerarquia__c, IsTile__c, IsSpecialTile__c
            FROM   Product2
            WHERE  Id = :productId
            LIMIT  1
        ];
        if (prods.isEmpty()) { return 0; }
        return computeSurcharge(prods[0].Jerarquia__c, prods[0].IsTile__c, prods[0].IsSpecialTile__c);
    }

    /* ========================================================= */
    /* PRIVATE                                                    */
    /* ========================================================= */

    private void applyRate(ZSFDesPalet__x row) {
        if (row.CurrencyCode__c != CURRENCY_PERCENT) {
            throw new InvalidRateException(
                'ZSFDesPalet__x: CurrencyCode__c expected % but got ' + row.CurrencyCode__c);
        }
        surchargeRate    = row.ConditionRate__c != null ? row.ConditionRate__c : 0;
        productHierarchy = row.ProductHierarchy__c;
    }

    /**
     * Core eligibility check. Extracted to allow unit testing without DB records.
     * - If productHierarchy is set: qualifies if Jerarquia__c starts with the prefix.
     * - If productHierarchy is blank: fallback — qualifies if IsTile__c && !IsSpecialTile__c.
     */
    @TestVisible
    private Decimal computeSurcharge(String jerarquia, Boolean isTile, Boolean isSpecialTile) {
        if (String.isNotBlank(productHierarchy)) {
            if (String.isBlank(jerarquia)) { return 0; }
            return jerarquia.startsWith(productHierarchy) ? surchargeRate : 0;
        }
        return (isTile == true && isSpecialTile != true) ? surchargeRate : 0;
    }

    /* ========================================================= */
    /* EXCEPTIONS                                                 */
    /* ========================================================= */

    public class InvalidRateException extends Exception {}
}