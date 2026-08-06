@isTest
public with sharing class OpportunityTeamMembersSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 1);
        OpportunityTeamMember teamMember = new OpportunityTeamMember(OpportunityId = opps[0].Id, UserId = UserInfo.getUserId());
        insert teamMember;
    }

    @isTest
    private static void selectById() {
        Set<Id> teamMembers = new Set<id>();
        for(OpportunityTeamMember l : [Select Id from OpportunityTeamMember]) {
            teamMembers.add(l.id);
        }

        List<OpportunityTeamMember> result = new OpportunityTeamMembersSelector().selectById(teamMembers);
        System.assertEquals(1, result.size(), '1 Team member expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        OpportunityTeamMember evt = [Select Id from OpportunityTeamMember LIMIT 1];
        OpportunityTeamMember result = new OpportunityTeamMembersSelector().selectById(evt.Id);
        System.assert(result != null, 'No se ha encontrado el Team member');
    }
}