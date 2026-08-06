@isTest
public with sharing class OpportunityMailsTest {
  @testSetup static void setup() {
    Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    OpportunitySettings__c newOppSetting = new OpportunitySettings__c(Name = 'GB', Country__c = 'GB', novalidcreation_mailto__c = 'ivan.losilla@porcelanosagrupo.com');
    insert newOppSetting;
  }

  @isTest
  static void alertNotValidCreation() {
    User auxUser = DataFactoryUser.createUKUser();
      Map<String,Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
      Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();	
      String retailRecTypeId = recTypeMap.get('Project_retail').getRecordTypeId();

      User u = [SELECT Id, CountryCode, Sales_org__c, countries__c, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c, ProfileId from User where Id =: auxUser.Id LIMIT 1][0];
      Opportunity opp = new Opportunity();
      System.runAs(u) {
        Account acc = new Account(Name = 'Test Account #2', RecordTypeId=rtId, 
                          BillingCountryCode = 'GB',
                          BillingCity = 'London',
                          BillingPostalCode = 'BS1 3ND');
        insert acc;
        opp = new Opportunity(Name = 'Test Retail Opportunity',
                          AccountId = acc.Id,
                          countryCode__c = 'ES',
                          RecordTypeId = retailRecTypeId,
                          StageName = 'Qualification',
                          roomTypeBathroom__c = 1,
                          CloseDate = System.today());
        insert opp;
      }

      OpportunityMails.alertNotValidCreation(new Set<Id>{opp.Id});
      Integer invocations = Limits.getEmailInvocations();
      System.assert(invocations > 0, 'Mail not sent. Mails sent: ' + invocations);
  }
}