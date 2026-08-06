@isTest
private class AccountSyncEvaluatorTest {

    @isTest
    static void testSyncToSAP_PersonAccount_True() {
        // Simular un cambio en los datos de una Person Account
        Account oldAccount = DataFactoryAccount.createPersonAccounts(1)[0];
        Account newAccount = oldAccount.clone();
        newAccount.FirstName = 'JohnnyP'; // Cambiar el valor de FirstName

        Test.startTest();
        Boolean result = AccountSyncEvaluator.syncToSAP(newAccount, oldAccount);
        Test.stopTest();

        Assert.areEqual(true, result, 'Se esperaba true debido a un cambio en FirstName.');
    }

    @isTest
    static void testSyncToSAP_PersonAccount_False() {
        // Simular que no hay cambios en los datos de una Person Account
        Account oldAccount = DataFactoryAccount.createPersonAccounts(1)[0];
        Account newAccount = oldAccount.clone();

        Test.startTest();
        Boolean result = AccountSyncEvaluator.syncToSAP(newAccount, oldAccount);
        Test.stopTest();

        Assert.areEqual(false, result, 'Se esperaba false ya que no hubo cambios.');
    }

    @isTest
    static void testSyncToSAP_BusinessAccount_True() {
        // Simular un cambio en los datos de una Business Account
        Account oldAccount = DataFactoryAccount.createBusinessAccounts(1)[0];
        Account newAccount = oldAccount.clone();
        newAccount.Name = 'Acme Corp'; // Cambiar el valor de Name

        Test.startTest();
        Boolean result = AccountSyncEvaluator.syncToSAP(newAccount, oldAccount);
        Test.stopTest();

        Assert.areEqual(true, result, 'Se esperaba true debido a un cambio en Name.');
    }

    @isTest
    static void testSyncToSAP_BusinessAccount_False() {
        // Simular que no hay cambios en los datos de una Business Account
        Account oldAccount = DataFactoryAccount.createBusinessAccounts(1)[0];
        Account newAccount = oldAccount.clone();

        Test.startTest();
        Boolean result = AccountSyncEvaluator.syncToSAP(newAccount, oldAccount);
        Test.stopTest();

        Assert.areEqual(false, result, 'Se esperaba false ya que no hubo cambios.');
    }
}