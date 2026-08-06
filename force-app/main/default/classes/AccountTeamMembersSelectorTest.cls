@isTest
public with sharing class AccountTeamMembersSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);
        AccountTeamMember display = new AccountTeamMember(AccountId = accs[0].Id, UserId = UserInfo.getUserId());
        insert display;
    }

    @isTest
    private static void selectById() {
        Set<Id> teamMembers = new Set<id>();
        for(AccountTeamMember l : [Select Id from AccountTeamMember]) {
            teamMembers.add(l.id);
        }

        List<AccountTeamMember> result = new AccountTeamMembersSelector().selectById(teamMembers);
        System.assertEquals(1, result.size(), '1 Team member expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        AccountTeamMember evt = [Select Id from AccountTeamMember LIMIT 1];
        AccountTeamMember result = new AccountTeamMembersSelector().selectById(evt.Id);
        System.assert(result != null, 'No se ha encontrado el Team member');
    }
}