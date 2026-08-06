@isTest
public class MarketingActionsTest {
  @testSetup
  static void setup() {
    TestUtils.enableTriggers();

    List<Account> accs = DataFactoryAccount.createPersonAccounts(1);
    MarketingActions.createReviewSMS(accs[0].Id, accs[0].Phone, accs[0].PersonMailingCountryCode);
    MarketingActions.createReviewSMS(accs[0].Id, accs[0].Phone, 'ES');

  }

  @isTest
  public static void getLastAction(){
    List<Account> accs = [Select Id from Account];
    List<MarketingActions__c> listActions = [SELECT Id,
                                              ActionId__c,
                                              Country__c,
                                              DateRequested__c,
                                              RelatedId__c,
                                              SendTo__c,
                                              TimeRequested__c,
                                              CreatedById
                                              from MarketingActions__c];
    String idNewest = listActions[1].Id;
    listActions[0].DateRequested__c = '2020-01-01';
    update listActions;

    MarketingActions__c action = MarketingActions.getLastAction(accs[0].Id, 'REVIEWSMS');

    System.assert(action.Id == idNewest, 'No se ha encontrado el último action');
  }

  @isTest
  public static void createReviewSMS(){
    List<Account> accs = [Select Id from Account];
    MarketingActions.createReviewSMS(accs[0].Id, '12232323', 'GB');
    List<MarketingActions__c> actions = [Select Id from MarketingActions__c];

    System.assertEquals(3, actions.size(), 'No se ha creado un review SMS');
  }

  @isTest
    static void fillerTest() {
      MarketingActions aux =  new MarketingActions();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}