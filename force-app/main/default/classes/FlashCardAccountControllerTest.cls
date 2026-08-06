@istest public class FlashCardAccountControllerTest {
    
    @testsetup public static void setup() {
        TestUtils.enableTriggers();
    }
    
    @isTest public static void getAccount() {
    	Account account = DataFactoryAccount.createPersonAccounts(1)[0];
        Account result = FlashCardAccountController.getAccount(account.Id);
        System.assertEquals(result.Id, account.Id, 'The returned account  does not match the requested one');
    }

}