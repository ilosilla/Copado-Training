/**
 * @author         Ramón Prades
 * @date           November 2023
 * @description    System-wide utility methods
*/
public class SystemCommons {
    /**
     * Builds a URL to link to the object
     */
    public static String getObjectURL(Id oid) {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/' + oid;
    }
}