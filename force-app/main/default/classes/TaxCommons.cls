/**
* @author Ivan Losilla
* @date July 2024
* @group Taxes
* @description Common methods related to taxes
*/
public class TaxCommons {
    
    public static Decimal getSalesOrgTax(String salesOrg) {
        Decimal percent = 0;
        Sales_Org__c[] orgs = new SalesOrgsSelector().selectBySAPId(new Set<String>{salesOrg});
        if (orgs.size() > 0) {
            percent = orgs[0].TaxPercent__c;
        }
        return percent;
    }

    /**
     * Checks if the Siret is valid. The formula to check if the siret is valid
     * https://en.wikipedia.org/wiki/SIRET_code
     */
    public static Boolean isValidSiret(String input) {
        // Verificar que la longitud sea 14
        if (input == null || input.length() != 14) {
            return false;
        }

        Integer total = 0;
        Boolean shouldDouble = true;
        
        // Recorrer la cadena desde el penúltimo carácter hacia el primero
        for (Integer i = input.length() - 2; i >= 0; i--) {
            Integer digit = Integer.valueOf(input.substring(i, i + 1));
            if (shouldDouble) {
                digit *= 2;
                if (digit > 9) {
                    digit -= 9;
                }
            }
            total += digit;
            shouldDouble = !shouldDouble;
        }
        
        // Obtener el último dígito de la cadena
        Integer lastDigit = Integer.valueOf(input.substring(input.length() - 1));
        
        // Verificar si la suma total más el último dígito es divisible por 10
        return Math.mod((total+lastDigit),10) == 0;
    }
    
    /**
     * Returns the SIREN value through the SIRET (9 first digits from the SIRET)
     */
    public static String getSirenFromSiret(String siret) {
        // Verificar que la longitud del SIRET sea 14
        if (siret == null || siret.length() != 14) {
            throw new IllegalArgumentException(Label.account_siret_format);
        }

        // Extraer los primeros 9 dígitos como el código SIREN
        String siren = siret.substring(0, 9);
        return siren;
    }

    // Valida CRN del Reino Unido
    public static Boolean isValidCRN(String crn) {
        if (String.isBlank(crn)) return false;

        // Expresión regular: 8 dígitos o 2 letras seguidas de 6 dígitos
        String crnPattern = '^(\\d{8}|[A-Z]{2}\\d{6})$';
        return Pattern.matches(crnPattern, crn.toUpperCase());
    }

    /* UK (Standard = 9 digits), (Branches = 12 digits), (Government = GD + 3 digits), (Health authority = HA + 3 digits)
    * https://gist.github.com/marcinlerka/630cc05d11bb10c5f1904506ff92abcd
    */
    public static Boolean isValidUKVAT(String vat) {
        if (String.isBlank(vat)) return false;

        vat = vat.replaceAll('\\s+', '').toUpperCase();
        String vatPattern = '^(GB)?\\d{9}$|^(GD|HA)\\d{3}$';
        return Pattern.matches(vatPattern, vat);
    }
}