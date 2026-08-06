trigger PEUpdateOpportunityTrigger on PEUpdateOpportunity__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PEUpdateOpportunity__e pe : Trigger.New) {
        if (pe.fieldChanged__c.toUpperCase() == 'STAGENAME'){
            idsUpdateLastActivity.add(pe.ObjectId__c);
        }
    }

    ActivityDateService.updateFromOpportunities(idsUpdateLastActivity);
}