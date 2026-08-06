trigger PENewEventTrigger on PENewEvent__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewEvent__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromEvents(idsUpdateLastActivity);
}