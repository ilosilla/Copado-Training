/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		OpportunityTeamMembers
* @description 	opportunity team members selector class
*/
public class OpportunityTeamMembersSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return OpportunityTeamMember.sObjectType;
    }

    public List<OpportunityTeamMember> selectById(Set<Id> recordIds){
        return (List<OpportunityTeamMember>) selectSObjectsById(recordIds);
    }

    public OpportunityTeamMember selectById(Id recordId){
        List<OpportunityTeamMember> listOppTeamMembers = (List<OpportunityTeamMember>) selectSObjectsById(new Set<Id>{recordId});
        if (listOppTeamMembers.size() == 1) {
            return listOppTeamMembers[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            OpportunityTeamMember.Id,
            OpportunityTeamMember.OpportunityId,
            OpportunityTeamMember.TeamMemberRole,
            OpportunityTeamMember.UserId,
            
            // Admin fields
            OpportunityTeamMember.OpportunityAccessLevel,
            OpportunityTeamMember.CreatedById,
            OpportunityTeamMember.CreatedDate,
            OpportunityTeamMember.LastModifiedById
        };
    }
}