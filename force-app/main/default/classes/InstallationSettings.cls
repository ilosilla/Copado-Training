/**
* @author Ivan Losilla Perez
* @date 10-2020
*
* @group Installations
* @group-content ../../ApexDocContent/InstallationSettings.htm
*
* @description Restrieve InstallatioSettings data
*/
public class InstallationSettings {

    @testvisible
    public static Map<String, InstallationSettings__c> getInstallationSettings() {
        List<InstallationSettings__c> listInsSettings = [SELECT id, Name, bccDevelopers__c, country__c, skipSOW__c FROM InstallationSettings__c];
        Map<String, InstallationSettings__c> mapSettings = new Map<String,InstallationSettings__c>();

        for (InstallationSettings__c setting : listInsSettings) {
            mapSettings.put(setting.country__c, setting);
        }
        return mapSettings;
    } // getInstallationSettings
} // Class