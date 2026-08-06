/**
 * @author         Ramón Prades
 * @date           July 2024
 * @layer          Selector
 * @description    Object Audit Trail
*/
public with sharing class ObjectAuditTrailsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'ObjectAuditTrail__c';
    }

    public ObjectAuditTrail__c getLastCaseTrail(Id caseId, String trailType) {
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('CaseId__c = :caseId AND AuditTrailType__c = :trailType');
        zflib_QueryFactory.Ordering ordering = new zflib_QueryFactory.Ordering(ObjectAuditTrail__c.CreatedDate, zflib_QueryFactory.SortOrder.DESCENDING);        
        query.setOrdering(ordering);
        query.setLimit(1);
        List<ObjectAuditTrail__c> records = (List<ObjectAuditTrail__c>) Database.query( query.toSOQL());
        if (records.size() > 0) {
            return records[0];
        } else {
            return null;
        }
    }

    public Map<Id, ObjectAuditTrail__c> getLastCaseTrail(Set<Id> caseIds, String trailType) {
        Map<Id, ObjectAuditTrail__c> results = new Map<Id, ObjectAuditTrail__c>();
        for (Id caseId : caseIds) {
            ObjectAuditTrail__c lastTrail = getLastCaseTrail(caseId, trailType);
            if (lastTrail != null) {
                results.put(caseId, lastTrail);
            }
        }
        return results;
    }

}