@IsTest
public class PORSAIntegrationSettingsTest {

    public static void setDefaultSettings(PorsaIntegrationSettings__c defaults) {
        upsert defaults;
    }
    
    @IsTest
    static void testIsSendClaimsEnabled_True() {
        // Insertar el registro de Custom Setting (modo List)
        PorsaIntegrationSettings__c defaults = new PorsaIntegrationSettings__c();
        defaults.SendClaims__c = true;
        setDefaultSettings(defaults);

        Test.startTest();
        Boolean result = PORSAIntegrationSettings.SendClaims;
        Test.stopTest();

        System.assertEquals(true, result, 'Expected SendClaims__c to be true');
    }

    @IsTest
    static void testIsSendClaimsEnabled_False() {
        Test.startTest();
        Boolean result = PORSAIntegrationSettings.SendClaims;
        Test.stopTest();

        System.assertEquals(false, result, 'Expected SendClaims__c to be false');
    }
 
}