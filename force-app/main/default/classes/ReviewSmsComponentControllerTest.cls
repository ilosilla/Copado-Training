@isTest
public class ReviewSmsComponentControllerTest {
  @testSetup
  static void setup() {
    TestUtils.enableTriggers();
    List<Account> listAcc = new List<Account>();

    listAcc.addAll(DataFactoryAccount.createPersonAccounts(1));
    MarketingActions.createReviewSMS(listAcc[0].Id, '+61411111111', 'US');
    MarketingActions.createReviewSMS(listAcc[0].Id, '+3499999999', 'ES');

  }

  @isTest
  public static void getLastReviewSMS(){
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

    MarketingActions__c action = ReviewSmsComponentController.getLastReviewSMS(accs[0].Id);

    System.assert(action.Id == idNewest, 'No se ha encontrado el último Review');
  }

  @isTest
  public static void createReviewSMS(){
    List<Account> listAcc = new List<Account>();
    listAcc.addAll(DataFactoryAccount.createBusinessAccounts(1));
    ReviewSmsComponentController.createReviewSMS(listAcc[0].Id, listAcc[0].Phone, listAcc[0].PersonMailingCountryCode);
    List<Account> accs = [Select Id from Account];
    ReviewSmsComponentController.createReviewSMS(accs[0].Id, '+3499999999', 'GB');
    List<MarketingActions__c> actions = [Select Id from MarketingActions__c];

    System.assertEquals(4, actions.size(), 'No se ha creado un review SMS');
  }

  @isTest
  public static void canReviewSMS(){
      List<Account> accs = [Select Id, Owner.CountryCode from Account];
    User usr = DataFactoryUser.createUKUser();

    System.assertEquals(false, ReviewSmsComponentController.canReviewSMS(accs[0].Id), 'no ha de poder crear Review SMS');
    

    CountrySettings__c newCountrySetting = new CountrySettings__c(Name = 'United Kingdom', Country__c = accs[0].Owner.CountryCode, enableREVIEWSMS__c = true);
    insert newCountrySetting;

    System.assertEquals(true, ReviewSmsComponentController.canReviewSMS(accs[0].Id), 'Ha de poder crear Review SMS');

  }

  @isTest
  public static void checkValidPhone(){
      String phone = '123-123123-123 .55';
      System.assertEquals(true, ReviewSmsComponentController.checkValidPhone(phone), 'Debería ser un teléfono válido');
      phone = '2864 HTG (56)';
      System.assertEquals(false, ReviewSmsComponentController.checkValidPhone(phone), 'Debería ser un teléfono válido');
  }
}