@IsTest
public inherited sharing class OpportunitySettingsTest {
  @testSetup static void setup() {
    TestUtils.enableTriggers();
    OpportunitySettings__c newOppSetting = new OpportunitySettings__c(Name = 'GB', Country__c = 'GB', novalidcreation_mailto__c = 'ivan.losilla@porcelanosagrupo.com');
    insert newOppSetting;
  }

  @isTest
  static void getOpportunitySettings() {
    Map<String, OpportunitySettings__c> mapSettings = OpportunitySettings.getOpportunitySettings();

    System.assert(mapSettings.containsKey('GB'), 'No lee correctamente el Opportunity Settings');
    System.assert(mapSettings.containsKey('ES') == false, 'No lee correctamente el Opportunity Settings');
  }

  @isTest
  static void getCreateValidationMailsTo() {
    Map<String, List<String>> mapSettings = OpportunitySettings.getCreateValidationMailsTo();

    System.assert(mapSettings.containsKey('GB'), 'No lee correctamente el Opportunity Settings');
    List<String> oppSet = mapSettings.get('GB');
    System.assert(oppSet[0] == 'ivan.losilla@porcelanosagrupo.com', 'No lee el valor correcto del Setting');
  }
}