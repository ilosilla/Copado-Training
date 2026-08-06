/**
 * @author         Ramón Prades
 * @date           December 2025
 * @group          B2B
 * @description    Service class for calculating shipping rates based on weight blocks and state rules.
 *                 The current implementation applies only to US shipments and selects a B2BShippingRate__c
 *                 rule by store, sales organization, country, state, and shipping method.
 *                 -----------------------------------------------------
 *                 Key Features:
 *                 - Applies only to US shipping rules
 *                 - Selects UPS or Standard Shipping depending on total shipment weight
 *                 - Calculates shipping cost in weight blocks (rounds up total weight to nearest block)
 *                 - Resolves the applicable rule by state and Priority__c
 *                 - Returns null if no matching active rule is found
 *                 -----------------------------------------------------
 *                 Usage:
 *                 Call getRateForWeightBlocks() with store label, country code, state code, and shipment weight
 *                 to retrieve the calculated shipping rate or null if no rule applies.
 */ 
public class B2B_ShippingRateService {

    public static final Set<String> alphaPost = new Set<String>{ 'GB', 'CA' };
    public static final Decimal LB_PER_KG = 2.20462;

    public static final String US_UPS = 'US-UPS-60';
    public static final String US_STD = 'US-STD';
    public static final Integer MAX_LB_UPS = 60;

    public class RateResultDTO {
        public Decimal totalAmount;      // coste total final (bloques * unitAmount)
        public Decimal unitAmount;       // importe unitario (Amount__c de la regla)
        public Decimal blockWeight;    // peso por bloque (WeightKg__c)
        public String weightUnit;     // unidad de peso (si se necesita)
        public String currencyCode;     // moneda del coste
        public Id rateId;                // Id de la regla aplicada
        public String carrier;
    }

    /**
     * Calcula el coste de envío dado store, país, postcode bruto y peso total del envío.
     * Devuelve RateResultDTO o null si no hay regla aplicable.
     */
    public static RateResultDTO getRateForWeightBlocks(String storeLabel, String countryCode, String stateCode, Decimal shipmentWeightKg) {
        if (String.isBlank(storeLabel) ||
            String.isBlank(countryCode) ||
            String.isBlank(stateCode) ||
            shipmentWeightKg == null ||
            shipmentWeightKg <= 0) {
            return null;
        }

        if (countryCode != 'US') {
            return null; // Solo aplicamos esta lógica para US, el resto de países no tienen reglas de envío configuradas
        }

        Decimal totalWeightInLb = shipmentWeightKg * LB_PER_KG;
        String shippingMethod = US_STD; // Default
        if (totalWeightInLb <= MAX_LB_UPS) {
            shippingMethod = US_UPS;
        }

        B2BShippingRate__c rule = getStateBasedRule(storeLabel, countryCode, stateCode, shippingMethod);
        RateResultDTO result = null;
        if (rule != null) {                   
            Decimal blockWeight = rule.Weight__c;
            if (blockWeight == null || blockWeight <= 0) {
                blockWeight = 999999;
            }
            Integer blocks = (Integer) Math.ceil(totalWeightInLb / blockWeight);
            result                 = new RateResultDTO();
            result.unitAmount      = rule.Amount__c;
            result.blockWeight     = rule.Weight__c;
            result.weightUnit      = rule.WeightUnit__c;
            result.currencyCode    = rule.CurrencyIsoCode;
            result.rateId          = rule.Id;
            result.totalAmount     = rule.Amount__c * blocks;
            result.carrier         = shippingMethod == US_UPS ? 'UPS Shipping' : 'Standard Shipping';
            result.carrier         += ' (' + stateCode + ')';
        }
        return result;


        /* Comentado de monemnto porque implemento USA de prisa
         * Recuperar cuando haga falta
         */
        /*
        String normPost = postCode.trim().toUpperCase();
        Boolean postalNumeric = isPostalNumericCountry(countryCode);
        RateResultDTO result = null;
        Decimal totalWeight = shipmentWeightKg;

        B2BShippingRate__c rule = postalNumeric
            ? getNumericPostalCandidates(storeLabel, countryCode, normPost)
            : getAlphanumericPostalCandidates(storeLabel, countryCode, normPost);
      
        if (rule != null) {                   
            Decimal blockWeight = rule.Weight__c;
            if (rule.WeightUnit__c == 'lb') {
                totalWeight = shipmentWeightKg * LB_PER_KG; // lbs to kg
                totalWeight = totalWeight.setScale(0, RoundingMode.HALF_UP);
            }
            if (blockWeight == null || blockWeight <= 0) {
                blockWeight = 999999;
            }
            Integer blocks = (Integer) Math.ceil(totalWeight / blockWeight);
            result                 = new RateResultDTO();
            result.unitAmount      = rule.Amount__c;
            result.blockWeight     = rule.Weight__c;
            result.weightUnit      = rule.WeightUnit__c;
            result.currencyCode    = rule.CurrencyIsoCode;
            result.rateId          = rule.Id;
            result.totalAmount     = rule.Amount__c * blocks;
        }

        return result;
        */
    }

    private static B2BShippingRate__c getStateBasedRule(String storeLabel, String countryCode, String stateCode, String shippingMethod) {
        String salesOrg = [SELECT Default_Sales_Organization__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Default_Sales_Organization__c;
        List<B2BShippingRate__c> candidates = [
            SELECT Id, Weight__c, WeightUnit__c, Amount__c, CurrencyIsoCode, Priority__c
            FROM B2BShippingRate__c
            WHERE Store__c = :storeLabel
              AND SalesOrg__c = :salesOrg
              AND CountryCode__c = :countryCode
              AND StateCode__c = :stateCode
              AND ShippingMethod__c = :shippingMethod
              AND Active__c  = true
            ORDER BY Priority__c ASC
            LIMIT 1
        ];
        return candidates.size() > 0 ? candidates[0] : null;
    }   
        

    /* Guardado de momento hasta que reactive la entrega por postcode
    private static B2BShippingRate__c getNumericPostalCandidates(String storeLabel, String countryCode, String postCode) {
        List<B2BShippingRate__c> candidates = [
            SELECT Id, PostcodeFrom__c, PostcodeTo__c, Weight__c, WeightUnit__c, Amount__c, CurrencyIsoCode, Priority__c
            FROM B2BShippingRate__c
            WHERE Store__c = :storeLabel
              AND CountryCode__c = :countryCode
              AND Active__c  = true
              AND PostcodeFrom__c <= :postCode 
              AND PostcodeTo__c >= :postCode
            ORDER BY Priority__c ASC
            LIMIT 1
        ];
        return candidates.size() > 0 ? candidates[0] : null;
    }

    private static B2BShippingRate__c getAlphanumericPostalCandidates(String storeLabel, String countryCode, String postCode) {
        
        List<String> variants = generatePostcodeVariants(countryCode, postCode);
        
        if (variants.isEmpty()) {
            return null;
        }

        List<B2BShippingRate__c> candidates = [
            SELECT Id, PostcodeFrom__c, Weight__c, WeightUnit__c, Amount__c, CurrencyIsoCode, Priority__c
            FROM B2BShippingRate__c
            WHERE Store__c = :storeLabel
              AND CountryCode__c = :countryCode
              AND Active__c = true
              AND PostcodeFrom__c IN :variants
            ORDER BY Priority__c ASC
            LIMIT 1
        ];

        return candidates.size() > 0 ? candidates[0] : null;
    }

    private static Boolean isPostalNumericCountry(String countryCode) {
        Set<String> alphaPost = new Set<String>{ 'GB', 'CA' };
        return !alphaPost.contains(countryCode.toUpperCase());
    }

    private static List<String> generatePostcodeVariants(String countryCode, String postCode) {
    
        List<String> result = new List<String>();
        String cc = countryCode.toUpperCase();

        // Añadimos como variante el postcode “tal cual” (normalizado mayúsculas)
        result.add(postCode);

        if (cc == 'GB' || cc == 'CA') {
            // Intentamos separar por espacio — outward / inward (UK) o FSA + LDU (CA)
            List<String> parts = postCode.split('\\s+');
            if (parts.size() == 2) {
                result.add(parts[0]);
            } 
        }

        return result;
    }
        */
}