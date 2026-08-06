/**
 * @author         Ramón Prades
 * @date           August 2024
 * @layer          Selectors
 * @description    Reads sales organisations data
*/
public with sharing class SalesOrgsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'Sales_Org__c';
    }

    public Sales_Org__c[] selectBySAPId(Set<String> sapCodes){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('SalesOrg__c in :sapCodes');
        return Database.query( query.toSOQL() );
     }
} // class