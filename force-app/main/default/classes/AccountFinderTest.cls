@isTest public class AccountFinderTest {

    @TestSetup static void makeData() {
        TestUtils.enableTriggers();
    }

    @isTest public static void getPersonAccountFromEmail() {
        DataFactoryAccount.createPersonAccounts(1);
        Account acc = [select Id, PersonEmail from Account];        
        Id id = AccountFinder.getPersonAccountFromEmail(acc.PersonEmail);
        System.assertEquals(acc.Id, id, 'Account not found from email');
        id = AccountFinder.getPersonAccountFromEmail('not_valid@email.sdfds');
        System.assertEquals(null, id, 'Account should be null (email unknown)');
    }        

    @isTest public static void getTradeAccountFromEmail() {
        DataFactoryAccount.createBusinessAccounts(1);
        Account acc = [select Id, Business_Email__c from Account];        
        Id id = AccountFinder.getTradeAccountFromEmail(acc.Business_Email__c);
        System.assertEquals(acc.Id, id, 'Account not found from email');
        id = AccountFinder.getTradeAccountFromEmail('not_valid@email.sdfds');
        System.assertEquals(null, id, 'Account should be null (email unknown)');
    }        
    
}