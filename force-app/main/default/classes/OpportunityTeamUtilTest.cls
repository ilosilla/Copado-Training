@isTest public class OpportunityTeamUtilTest {
    
    @testSetup private static void setup() {
        TestUtils.enableTriggers();
    }
    
    @isTest private static void get() {
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
        OpportunityTeamMember member = OpportunityTeamUtil.get(opp.Id, UserInfo.getUserId());
        Id memberId = null;
        if (member != null) {
            memberId = member.UserId;
        }
		System.assertEquals(UserInfo.getUserId(), memberId, 'Current user should have been in the opportunity team');
    }
}