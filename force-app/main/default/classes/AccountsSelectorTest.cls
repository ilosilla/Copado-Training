@isTest
public with sharing class AccountsSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(10);
    }

    @isTest
    private static void selectById() {
        Set<Id> accountIds = new Set<id>();
        for(Account l : [Select Id from Account]) {
            accountIds.add(l.id);
        }

        List<Account> result = new AccountsSelector().selectById(accountIds);
        System.assertEquals(10, result.size(), '10 accounts expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Account acc = [Select Id from Account LIMIT 1];
        Account result = new AccountsSelector().selectById(acc.Id);
        System.assert(result != null, 'No se ha encontrado el Account');
    }

}