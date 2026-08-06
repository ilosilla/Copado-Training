@SuppressWarnings('PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces, PMD.ExcessiveParameterList')
/**
 * @author         Ramón Prades
 * @date           September 2025
 * @layer          Commons
 * @description    Product conversion routines
*/
public class UnitConversionCommons {

    private static final String VALID_UNITS = '|CJ|CJS|BOX|PZS|PCS|MT2|M2|FT2|SQF|';
    private static final Decimal FT2_TO_M2 = 0.092903;

    public static String sapUnitToSalesforce(String sapUnit) {
        String sforceUnit = sapUnit;
        if (sforceUnit == 'CS') sforceUnit = 'CJ';
        return sforceUnit;        
    }

    public static Decimal ConvertFromTo(Decimal quantity, String fromUnit, String toUnit, Factors cFactors) {        
        Decimal result;
        if (fromUnit == toUnit) {
            return quantity;
        }        
        if (isSquareFeet(fromUnit)) {
            Decimal quantityInM2 = quantity * FT2_TO_M2;
            result = ConvertFromTo(quantityInM2, 'MT2', toUnit, cFactors);
            return result;
        }
        if (isSquareFeet(toUnit)) {
            Decimal quantityInM2 = ConvertFromTo(quantity, fromUnit, 'MT2', cFactors);
            result = quantityInM2 / FT2_TO_M2;
            return result;
        }
        if (!isValid(fromUnit) || !isValid(toUnit)) {
            throw new ValidationException('Wrong unit');
        }
        if (cFactors.M2XBox > 0) {
            if (isBox(fromUnit)) {
                if (isPiece(toUnit)) result = quantity * cFactors.PcsXBox;            
                if (isSquareMetre(toUnit)) result = quantity * cFactors.M2XBox;
                if (isBox(toUnit)) result = quantity;
            } else if (isSquareMetre(fromUnit)) {
                if (isPiece(toUnit)) result = quantity * cFactors.PcsXBox / cFactors.M2XBox;
                if (isBox(toUnit)) result =  quantity / cFactors.M2XBox;
                if (isSquareMetre(toUnit)) result = quantity; 
            } else if (isPiece(fromUnit)) {
                if (isSquareMetre(toUnit)) result = quantity * cFactors.M2XBox / cFactors.PcsXBox;
                if (isBox(toUnit)) result = quantity / cFactors.PcsXBox;
                if (isPiece(toUnit)) result = quantity;
            }
        }
        return result;
    } // ConvertFromTo

    public static Decimal ConvertWeightFromTo(Decimal weight, String fromUnit, String toUnit, Factors cFactors) {
        return ConvertFromTo(weight, toUnit, fromUnit, cFactors);
    }

    public static Boolean isBox(String unit) {
        unit = unit?.toUpperCase();
        return (unit == 'CJ' || unit == 'CJS' || unit == 'BOX');
    }

    public static Boolean isPiece(String unit) {
        unit = unit?.toUpperCase();
        return (unit == 'PZS' || unit == 'PCS');
    }

    public static Boolean isSquareMetre(String unit) {
        unit = unit?.toUpperCase();
        return (unit == 'MT2' || unit == 'M2');
    }

    public static Boolean isSquareFeet(String unit) {
        unit = unit?.toUpperCase();
        return (unit == 'FT2' || unit == 'SQF');
    }

    public static Boolean isValid(String unit) {
        String u = '|' + unit + '|';
        return VALID_UNITS.containsIgnoreCase(u);
    }

    public class Factors {        
        public Integer PcsXBox;        
        public Decimal M2XBox;
    }


}