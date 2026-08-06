/**
* @author Ramón Prades
* @date September 2020
*
* @group Opportunity 
* @group-content ../../ApexDocContent/Opportunities.htm
*
* @description Opportunity team utility methods
*/
public class OpportunityTeamUtil {
    
    public static OpportunityTeamMember get(String opportunityId, String userId) {        
        List<OpportunityTeamMember> team = [select Id, OpportunityId, UserId, TeamMemberRole, IsDeleted from OpportunityTeamMember 
                              	where OpportunityId = :opportunityId and UserId = :userId];
        if (team.size() == 0) {
            return null;
        } else {
            return team[0];
        }
    } // get
        
}