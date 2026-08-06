/**
 * Class Name     : BusinessStructureCommons
 * Author         : Ramón Prades
 * Created Date   : 2025-05-05
 * Description    : Utility class containing business logic and helpers related
 *                  to the internal structure of the company, such as Sales
 *                  Organisations, regional mappings, and structural redirections.
 */

 public without sharing class BusinessStructureCommons {

    /**
     * Returns the replacement SalesOrg code if one exists.
     * If there is no redirection defined, returns the original code.
     *
     * @param code The original SalesOrg code (e.g., '507')
     * @return The redirected code if it exists, or the same code
     * 
     * 
     * NOTE:
     * While it would be more flexible to store redirection mappings in the database,
     * this method uses hardcoded values for simplicity and performance reasons.
     *
     * SalesOrg redirections are infrequent and typically managed during controlled
     * data updates or organizational changes. By avoiding a database query,
     * we reduce complexity and dependency on external configuration for a case
     * that is relatively static.
     *
     * If redirection logic becomes more dynamic in the future, consider refactoring
     * this method to read from a custom metadata type or a configuration object.
     */
    public static String getRedirectedSalesOrg(String code) {
        // Hardcoded redirection map (old → new)
        Map<String, String> redirectionMap = new Map<String, String>{
            '504' => '514',
            '505' => '515',
            '506' => '516',
            '507' => '517',
            '508' => '518',
            '203' => '226',
            '206' => '227',
            '207' => '228',
            '208' => '229',
            '210' => '230',
            '218' => '231',
            '219' => '232'
        };
        return redirectionMap.containsKey(code) ? redirectionMap.get(code) : code;
    }

    /**
     * Gets the sales organization a plant belongs to
     */
    public static String getSalesOrgByPlant(String plant) {
        String org = null;
        List<SAPPlant__c> records = [
            SELECT SalesOrg__c
            FROM SAPPlant__c
            WHERE Plant__c = :plant AND IsDeleted__c = false
            LIMIT 1
        ];
        if (records.size() > 0) {
            org = records[0].SalesOrg__c;
        }

        return org;
    }

}