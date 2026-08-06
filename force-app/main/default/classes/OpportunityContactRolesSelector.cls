/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		OpportunityContactRoles
* @description 	opportunitiy contact roles selector class
*/
public class OpportunityContactRolesSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return OpportunityContactRole.sObjectType;
    }

    public List<OpportunityContactRole> selectById(Set<Id> recordIds){
        return (List<OpportunityContactRole>) selectSObjectsById(recordIds);
    }

    public OpportunityContactRole selectById(Id recordId){
        List<OpportunityContactRole> listcontactRoles = (List<OpportunityContactRole>) selectSObjectsById(new Set<Id>{recordId});
        if (listcontactRoles.size() == 1) {
            return listcontactRoles[0];
        }
        return null;
    }

    public List<OpportunityContactRole> selectByOpportunity(Id opportunityId){
        return Database.query(newQueryFactory().setCondition('opportunityId =:opportunityId').toSOQL());
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            OpportunityContactRole.Id,
            OpportunityContactRole.Account__c,
            OpportunityContactRole.ContactId,
            OpportunityContactRole.OpportunityId,
            OpportunityContactRole.IsPrimary,
            OpportunityContactRole.Role,
            OpportunityContactRole.ErrorMessage__c,
            OpportunityContactRole.SapStatus__c
        };
    }
}