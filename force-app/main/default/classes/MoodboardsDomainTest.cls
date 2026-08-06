@isTest
public class MoodboardsDomainTest {
    @testSetup
  static void setup() {
    TestUtils.enableTriggers();

    Account acc = Account_TestDataFactory.createBusinessAccount();
    Insert acc;

    Opportunity newOpp = Opportunity_TestDataFactory.createTrade(acc);
    Insert newOpp;

    Moodboard__c mood = new Moodboard__c(Opportunity__c = newOpp.id, Name = 'Test Moodboard');
    insert mood;

  }

  @IsTest
  static void urlMoodboard() {
    List<Moodboard__c> moodb = [SELECT Url__c, Opportunity__r.Owner.LanguageLocaleKey from Moodboard__c LIMIT 1];
    System.assert(moodb[0].Url__c == 'https://moodboard.porcelanosagrupo.com/#/templates/' + moodb[0].Opportunity__r.Owner.LanguageLocaleKey + '/SFORCE_' + moodb[0].Id, 'No se ha seteado la Url del moodboard');
  }

  @IsTest
  static void activityDate() {
    Test.startTest();
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Opportunity newOpp = Opportunity_TestDataFactory.createTrade(acc);
    insert newOpp;
    Moodboard__c aux = new Moodboard__c(Opportunity__c = newOpp.id, Name = 'Test Moodboard');
    acc.Last_Activity_Date__c = System.now().addDays(-8);
    update acc;
    insert aux;
    Test.stopTest();
    acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id =: acc.Id];
    System.assert(acc.Last_Activity_Date__c != null, 'No se ha seteado el Last Activity');
    System.assert(acc.Last_Activity_Date__c.date() == System.now().date(), 'No se ha actualizado el Last Activity');
  }
}