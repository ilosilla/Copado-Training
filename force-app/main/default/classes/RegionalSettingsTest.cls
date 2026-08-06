/**
  @author Ramón Prades
 * @date August 2020
 *
 * @group Settings
 * @group-content ../../ApexDocContent/Settings.htm
 *
 * @description Test class for the App configuration per region
 */

@isTest public class RegionalSettingsTest {
    	    
    @isTest private static void testProperties() {
        String region = getInstallationRegion();
        if (region != null) {
            RegionalSettings settings = new RegionalSettings(region);
            System.assertEquals(true, settings.installationsEnabled);
        }

        RegionalSettings settings2 = new RegionalSettings('333');
        System.assertEquals(false, settings2.installationsEnabled);        
    }
    
    private static String getInstallationRegion() {
        List<RegionalSettings__mdt> theList = [select SalesOrganization__c, InstallationsEnabled__c from RegionalSettings__mdt];
        for (RegionalSettings__mdt item :theList) {
            if (item.InstallationsEnabled__c) {
                return item.SalesOrganization__c;
            }
        }
        return null;
    }
    
}