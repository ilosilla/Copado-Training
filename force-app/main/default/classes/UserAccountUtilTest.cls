@isTest public class UserAccountUtilTest {
        
    @testSetup private static void testSetup() {
    	TestUtils.enableTriggers();    
    }
    
    @isTest private static void getUser() {
        Id account = testData();
        String userId = UserAccountUtil.getUser(account, 'INSTALLER');
        System.assertEquals(UserInfo.getUserId(), userId);            
    }
   
 	private static Id testData() {
    	Account account = DataFactoryAccount.createPersonAccounts(1)[0];
        UserAccounts__c user = new UserAccounts__c();        
        user.Account__c = account.Id;
        user.User__c = UserInfo.getUserId();
        user.Role__c = 'INSTALLER';
        insert user;
        return account.Id;
    }    
}