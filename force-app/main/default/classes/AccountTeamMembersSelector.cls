/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		AccountTeamMembers
* @description 	account team members selector class
*/
public class AccountTeamMembersSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return AccountTeamMember.sObjectType;
    }

    public List<AccountTeamMember> selectById(Set<Id> recordIds){
        return (List<AccountTeamMember>) selectSObjectsById(recordIds);
    }

    public AccountTeamMember selectById(Id recordId){
        List<AccountTeamMember> listAccTeamMembers = (List<AccountTeamMember>) selectSObjectsById(new Set<Id>{recordId});
        if (listAccTeamMembers.size() == 1) {
            return listAccTeamMembers[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            AccountTeamMember.Id,
            AccountTeamMember.AccountId,
            AccountTeamMember.TeamMemberRole,
            AccountTeamMember.UserId,
            
            // Admin fields
            AccountTeamMember.ContactAccessLevel,
            AccountTeamMember.OpportunityAccessLevel,
            AccountTeamMember.AccountAccessLevel,
            AccountTeamMember.CaseAccessLevel,
            AccountTeamMember.CreatedById,
            AccountTeamMember.CreatedDate,
            AccountTeamMember.LastModifiedById
        };
    }
}