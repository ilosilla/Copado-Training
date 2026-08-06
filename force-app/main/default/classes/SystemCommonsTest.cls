@isTest public class SystemCommonsTest {
    @isTest static void testObjectURL() {
        Account acc = DataFactoryAccount.createAccounts(1)[0];
        String url = SystemCommons.getObjectURL(acc.Id);
        Assert.isNotNull(url, 'A URL should have been returned');
    }
}