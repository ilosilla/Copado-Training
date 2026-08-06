/**
* @author Ivan Losilla Perez
* @date February 2021
*
* @group Settings
* @group-content ../../ApexDocContent/CountrySettings.htm
*
* @description Retrieve Country Settings data
*/
public class CountrySettings {

    @testvisible
    public static Map<String, CountrySettings__c> getCountrySettings() {
        List<CountrySettings__c> listCountrySettings = [SELECT id, Name, Country__c, EnableREVIEWSMS__c, LeadDefaultOwnerID__c FROM CountrySettings__c];
        Map<String, CountrySettings__c> mapSettings = new Map<String,CountrySettings__c>();

        for (CountrySettings__c setting : listCountrySettings) {
            mapSettings.put(setting.Country__c, setting);
        }
        return mapSettings;
    } // getAccountSettings

    public static Map<String, Boolean> getReviewSms() {
        List<CountrySettings__c> listCountrySettings = [SELECT id, Name, Country__c, EnableREVIEWSMS__c, LeadDefaultOwnerID__c FROM CountrySettings__c];
        Map<String, Boolean> mapValues = new Map<String, Boolean>();

        for (CountrySettings__c setting : listCountrySettings) {
            mapValues.put(setting.Country__c, setting.EnableREVIEWSMS__c);
        }

        return mapValues;
    }
} // Class