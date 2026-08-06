@IsTest public class AccountTeamMembersDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(3);
    }

    @isTest static void addTeamMember() {
        Account acc = [Select Id, Last_Activity_Date__c, OwnerId from Account LIMIT 1];
        acc.Last_Activity_Date__c = acc.Last_Activity_Date__c.addDays(-8);
        update acc;

        acc = [Select Id, Last_Activity_Date__c, OwnerId from Account where Id =: acc.Id];
        DateTime beforeActivityDate = acc.Last_Activity_Date__c;
        
        Test.startTest();
        List<AccountTeamMember> accTeamMemberList = new List<AccountTeamMember>();
        accTeamMemberList.addAll(AccountTeamMember_TestDataFactory.createAccountTeamMembers(1, new Map<String, Object>{'LocaleSidKey' => 'en_US', 'Does_this_position_have_a_sales_budget__c' => 'No'},
        new Map<String, Object>{'AccountId' => acc.Id}));
        Insert accTeamMemberList;
        Test.stopTest();
        acc = [Select Id, Last_Activity_Date__c, OwnerId from Account where Id =: acc.Id];

        new AccountTeamMembersDomain(accTeamMemberList);
        
        System.assert(acc.Last_Activity_Date__c != beforeActivityDate, 'No se ha actualizado el Last Activity date');
    }
}