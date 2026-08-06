/**
* @author Ivan Losilla Perez
* @date January 2021
*
* @group Opportunity
* @group-content ../../ApexDocContent/OpportunitySettings.htm
*
* @description Retrieve Opportunity Settings data
*/
public class OpportunitySettings {

  @testvisible
  public static Map<String, OpportunitySettings__c> getOpportunitySettings() {
      List<OpportunitySettings__c> listOpportunitySettings = [SELECT id, Name, novalidcreation_mailto__c, country__c FROM OpportunitySettings__c];
      Map<String, OpportunitySettings__c> mapSettings = new Map<String,OpportunitySettings__c>();

      for (OpportunitySettings__c setting : listOpportunitySettings) {
          mapSettings.put(setting.country__c, setting);
      }
      return mapSettings;
  } // getOpportunitySettings

  public static Map<String, List<String>> getCreateValidationMailsTo() {
      List<OpportunitySettings__c> listOpportunitySettings = [SELECT id, Name, novalidcreation_mailto__c, country__c FROM OpportunitySettings__c];
      Map<String, List<String>> mapValues = new Map<String, List<String>>();
      for (OpportunitySettings__c accSetting : listOpportunitySettings) {
          if (accSetting.novalidcreation_mailto__c != null) {
              mapValues.put(accSetting.country__c, accSetting.novalidcreation_mailto__c.split(','));
            }
      }
      return mapValues;
  }
} // Class