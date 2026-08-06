trigger PENewDisplayTrigger on PENewDisplay__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewDisplay__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromDisplays(idsUpdateLastActivity);
}