@isTest public class AccountProxyTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();
    }

    @isTest static void testAccount() {
        Account account = DataFactoryAccount.createBusinessAccounts(1)[0];
        AccountProxy proxy = new AccountProxy(account.Id);
        System.assertEquals(account.Id, proxy.id, 'Id should match');
    }

    @isTest static void testPersonAccount() {
        Account account = DataFactoryAccount.createPersonAccounts(1)[0];
        AccountProxy proxy = new AccountProxy(account.Id);
        System.assertEquals(account.Id, proxy.id, 'Id should match');
    }

}