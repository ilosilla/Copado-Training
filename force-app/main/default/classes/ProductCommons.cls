/**
 * @author         Ramón Prades
 * @date           December 2024
 * @layer          Commons
 * @description    Utility methods to handle product related properties
*/
public class ProductCommons {
    
    /**
     * Normalizes a make by removing the "SIN MARCA" and converting it to upper case
     */
    public static String normalizeMake(String make) {
        String result = make;
        if (result == null || result?.toLowerCase() == 'sin marca') {
            result = '';
        }  
        return result?.toUpperCase();
    }

    /**
     * Gets the one-char make code from a make name (i.e. P from PORCELANOSA)
     */
    public static String makeCodeFromName(String makeName) {
        String result = normalizeMake(makeName);
        if (String.isNotBlank(result)) {
            if (result == 'KRION') {
                result = 'S';
            } else if (result?.toLowerCase() == 'URBATEK') {
                result = 'C';
            } else {
                result = result.substring(0,1);
            }
        }
        return result;
    }

    /**
     * Returns true if all the products are in the stock program
     */
    public static Boolean checkStockProgram(String salesOrg, Set<String> materialsSet) {
        Boolean result = true; 
        ZSFMatOrgv__x[] mats = [select Material__c, Stkprog__c from ZSFMatOrgv__x where Vkorg__c = :salesOrg and Material__c in :materialsSet];
        for (ZSFMatOrgv__x mat : mats) {
            result = result && mat.Stkprog__c;
        } 
        return result;
    }

}