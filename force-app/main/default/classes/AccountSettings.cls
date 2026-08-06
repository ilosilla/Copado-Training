/**
* @author Ivan Losilla Perez
* @date November
*
* @group Account
* @group-content ../../ApexDocContent/AccountSettings.htm
*
* @description Restrieve Account Settings data
*/
public class AccountSettings {

    @testvisible
    public static Map<String, AccountSettings__c> getAccountSettings() {
        List<AccountSettings__c> listAccountSettings = [SELECT id, Name, novalidcreation_mailto__c, country__c FROM AccountSettings__c];
        Map<String, AccountSettings__c> mapSettings = new Map<String,AccountSettings__c>();

        for (AccountSettings__c setting : listAccountSettings) {
            mapSettings.put(setting.country__c, setting);
        }
        return mapSettings;
    } // getAccountSettings

    public static Map<String, List<String>> getCreateValidationMailsTo() {
        List<AccountSettings__c> listAccountSettings = [SELECT id, Name, novalidcreation_mailto__c, country__c FROM AccountSettings__c];
        Map<String, List<String>> mapValues = new Map<String, List<String>>();

        for (AccountSettings__c accSetting : listAccountSettings) {
            mapValues.put(accSetting.country__c, accSetting.novalidcreation_mailto__c.split(','));
        }

        return mapValues;
    }
} // Class