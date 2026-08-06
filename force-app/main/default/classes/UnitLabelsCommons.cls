/**
 * Purpose: Resolve canonical unit labels from normalized unit codes using Custom Labels.
 *
 * Design notes:
 * - The class centralizes unit normalization and localized label retrieval.
 * - Custom Labels follow the convention dict_uni_<normalizedcode>_<abbr|one|many>.
 * - Unit aliases are normalized before resolving labels so callers can pass SAP or legacy values.
 * - If a translation is not available, the class falls back to English and finally to the normalized unit code.
 */
public class UnitLabelsCommons {

    private static final String DEFAULT_LANGUAGE = 'en_US';
    private static final String LABEL_PREFIX = 'dict_uni_';
    private static final String LABEL_SUFFIX_ABBR = '_abbr';
    private static final String LABEL_SUFFIX_ONE = '_one';
    private static final String LABEL_SUFFIX_MANY = '_many';
    private static final Integer DEFAULT_DECIMALS = 2;

    private static final Map<String, String> UNIT_NORMALIZATION = new Map<String, String>{
        'CS' => 'BOX',
        'CJ' => 'BOX',
        'CJS' => 'BOX',
        'BOX' => 'BOX',
        'PZS' => 'PCS',
        'PCS' => 'PCS',
        'UN' => 'UN',
        'BAG' => 'BAG',
        'PAL' => 'PAL',
        'KG' => 'KG',
        'L' => 'L',
        'MT2' => 'M2',
        'M2' => 'M2',
        'FT2' => 'SQF',
        'SQF' => 'SQF',
        'ROL' => 'ROL'
    };

    private static final Map<String, Integer> UNIT_DECIMALS = new Map<String, Integer>{
        'BOX' => 0,
        'PCS' => 0,
        'UN' => 0,
        'BAG' => 0,
        'PAL' => 0,
        'KG' => 2,
        'L' => 2,
        'M2' => 2,
        'SQF' => 2,
        'ROL' => 0
    };

    /* ========================================================= */
    /* PUBLIC DTOs                                               */
    /* ========================================================= */

    public class UnitLabelsDTO {
        public String abbreviation { get; private set; }
        public String singular { get; private set; }
        public String plural { get; private set; }
        public Integer decimals { get; private set; }

        public UnitLabelsDTO(String abbreviation, String singular, String plural, Integer decimals) {
            this.abbreviation = abbreviation;
            this.singular = singular;
            this.plural = plural;
            this.decimals = decimals;
        }
    }

    /* ========================================================= */
    /* PUBLIC METHODS (API)                                      */
    /* ========================================================= */

    public static UnitLabelsDTO getUnitLabels(String unitCode) {
        return getUnitLabels(unitCode, UserInfo.getLanguage());
    }

    public static UnitLabelsDTO getUnitLabels(String unitCode, String languageCode) {
        if (String.isBlank(unitCode)) {
            throw new ValidationException('Unit code is required.');
        }

        String normalizedUnitCode = normalizeUnit(unitCode);
        String resolvedLanguageCode = normalizeLanguageCode(languageCode);

        return new UnitLabelsDTO(
            getUnitLabelValue(normalizedUnitCode, LABEL_SUFFIX_ABBR, resolvedLanguageCode),
            getUnitLabelValue(normalizedUnitCode, LABEL_SUFFIX_ONE, resolvedLanguageCode),
            getUnitLabelValue(normalizedUnitCode, LABEL_SUFFIX_MANY, resolvedLanguageCode),
            getDecimals(normalizedUnitCode)
        );
    }

    public static Integer getDecimals(String unitCode) {
        if (String.isBlank(unitCode)) {
            throw new ValidationException('Unit code is required.');
        }

        String normalizedUnitCode = normalizeUnit(unitCode);
        if (UNIT_DECIMALS.containsKey(normalizedUnitCode)) {
            return UNIT_DECIMALS.get(normalizedUnitCode);
        }

        return DEFAULT_DECIMALS;
    }

    public static String formatQuantity(Decimal quantity, String unitCode) {
        if (quantity == null) {
            return '';
        }

        Integer decimals = getDecimals(unitCode);
        Decimal scaledQuantity = quantity.setScale(decimals, RoundingMode.HALF_UP);

        return String.valueOf(scaledQuantity);
    }

    public static String normalizeUnit(String unitCode) {
        if (String.isBlank(unitCode)) {
            return null;
        }

        String normalizedInput = unitCode.trim().toUpperCase();
        if (UNIT_NORMALIZATION.containsKey(normalizedInput)) {
            return UNIT_NORMALIZATION.get(normalizedInput);
        }

        return normalizedInput;
    }

    /* ========================================================= */
    /* PRIVATE METHODS                                           */
    /* ========================================================= */

    @TestVisible
    private static String normalizeLanguageCode(String languageCode) {
        if (String.isBlank(languageCode)) {
            return DEFAULT_LANGUAGE;
        }

        return languageCode.trim().replace('-', '_');
    }

    @TestVisible
    private static String getUnitLabelValue(String normalizedUnitCode, String labelSuffix, String languageCode) {
        String labelName = buildLabelName(normalizedUnitCode, labelSuffix);
        String fallbackValue = getFallbackValue(normalizedUnitCode);

        String translatedValue = getCustomLabelValue(labelName, languageCode);
        if (String.isNotBlank(translatedValue)) {
            return translatedValue;
        }

        String defaultValue = getCustomLabelValue(labelName, DEFAULT_LANGUAGE);
        if (String.isNotBlank(defaultValue)) {
            return defaultValue;
        }

        return fallbackValue;
    }

    @TestVisible
    private static String buildLabelName(String normalizedUnitCode, String labelSuffix) {
        return LABEL_PREFIX + normalizedUnitCode.toLowerCase() + labelSuffix;
    }

    private static String getCustomLabelValue(String labelName, String languageCode) {
        try {
            return System.Label.get('', labelName, languageCode);
        } catch (Exception ex) {
            return null;
        }
    }

    private static String getFallbackValue(String normalizedUnitCode) {
        return normalizedUnitCode;
    }
}