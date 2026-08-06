@IsTest
public inherited sharing class CountrySettingsTest {
  @testSetup static void setup() {
    TestUtils.enableTriggers();
    CountrySettings__c newCountrySetting = new CountrySettings__c(Name = 'United Kingdom', Country__c = 'GB', enableREVIEWSMS__c = true);
    insert newCountrySetting;
  }

  @isTest
  static void getCountrySettings() {
    Map<String, CountrySettings__c> mapSettings = CountrySettings.getCountrySettings();

    System.assert(mapSettings.containsKey('GB'), 'No lee correctamente el Country Settings');
    System.assert(mapSettings.containsKey('ES') == false, 'No lee correctamente el Country Settings');
  }

  @isTest
  static void getReviewSms() {
    Map<String, Boolean> mapSettings = CountrySettings.getReviewSms();

    System.assert(mapSettings.containsKey('GB'), 'No lee correctamente el Country Settings');
    Boolean countrySet = mapSettings.get('GB');
    System.assert(countrySet == true, 'No lee el valor correcto del Setting');
  }
}