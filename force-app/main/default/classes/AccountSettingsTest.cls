@IsTest
public inherited sharing class AccountSettingsTest {
  @testSetup static void setup() {
    TestUtils.enableTriggers();
    AccountSettings__c newAccSetting = new AccountSettings__c(Name = 'UK', Country__c = 'GB', novalidcreation_mailto__c = 'ivan.losilla@porcelanosagrupo.com');
    insert newAccSetting;
  }

  @isTest
  static void getAccountSettings() {
    Map<String, AccountSettings__c> mapSettings = AccountSettings.getAccountSettings();

    System.assert(mapSettings.containsKey('GB'), 'No lee correctamente el Account Settings');
    System.assert(mapSettings.containsKey('ES') == false, 'No lee correctamente el Account Settings');
  }

  @isTest
  static void getCreateValidationMailsTo() {
    Map<String, List<String>> mapSettings = AccountSettings.getCreateValidationMailsTo();

    System.assert(mapSettings.containsKey('GB'), 'No lee correctamente el Account Settings');
    List<String> accSet = mapSettings.get('GB');
    System.assert(accSet[0] == 'ivan.losilla@porcelanosagrupo.com', 'No lee el valor correcto del Setting');
  }
}