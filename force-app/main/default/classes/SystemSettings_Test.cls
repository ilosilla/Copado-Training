/**
 * Author           Ramón prades
 * Description      Tests SystemSettings
 * Date             May 2020
 * History              
 */

@isTest
private class SystemSettings_Test {

    @isTest static void testClassProperties() {
        System.assertEquals(16, SystemSettings.CPDeletionTime);
    }
    
    @isTest static void test_getSystemSettings() {
        System.assert(SystemSettings.adminProfiles <> null, 'SystemSettings.adminProfiles is null!');
        System.assert(SystemSettings.genericUsers <> null, 'SystemSettings.genericUsers is not null!');
        System.assert(SystemSettings.USNotifyWebLeads <> null, 'SystemSettings.USNotifyWebLeads is not null!');
    } // test_getSystemSettings

    @isTest static void isFeatureEnabled() {
        System.assertEquals(SystemSettings.underDevelopment('sap_status'), false, 'underDevelopment not working');
    }

    @isTest static void sapConnectionDown() {
        System.assertEquals(SystemSettings.sapConnectionDown(), false, 'sap should be not down');
    }

} // SystemSettings_Test