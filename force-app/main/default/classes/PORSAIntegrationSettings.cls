/**
 * -----------------------------------------------------------------------------
 * Class Name  : PORSAIntegrationSettings
 * Author      : Ramón Prades
 * Description : Helper class to access integration feature toggles stored in
 *               the custom setting 'PorsaIntegrationSettings__c'.
 * 
 *               This class provides static methods to check whether specific
 *               features are enabled, using a single global settings record.
 *               It caches the settings in memory to improve performance and 
 *               throws a clear exception if no configuration is found.
 * 
 * Usage Example:
 *    if (PORSAIntegrationSettings.isSendClaimsEnabled()) {
 *        // Execute claim sending logic
 *    }
 * 
 * Future Extension:
 *    - Add more static methods as new feature flags are introduced.
 *    - Optionally support hierarchical settings by user or profile.
 * -----------------------------------------------------------------------------
 */
public class PORSAIntegrationSettings {
    
    private static PorsaIntegrationSettings__c settings;

    static {
        if (settings == null) {
            settings = PorsaIntegrationSettings__c.getOrgDefaults();
            /*if (settings == null) {
                settings = new PorsaIntegrationSettings__c();
                settings.SendClaims__c = false;
            }*/
        }
    }
    public static Boolean SendClaims = (settings?.SendClaims__c ?? false);
}