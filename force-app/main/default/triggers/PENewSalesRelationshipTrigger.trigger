trigger PENewSalesRelationshipTrigger on PENewSalesRelationship__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    List<String> ids = new List<String>();

    for (PENewSalesRelationship__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
        ids.add(pe.ObjectId__c);
    }
    ActivityDateService.updateFromSalesRelationships(idsUpdateLastActivity);
    SalesRelationshipTriggerHandler.UpdateOwner(ids);
}