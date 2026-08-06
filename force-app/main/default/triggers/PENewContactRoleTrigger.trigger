trigger PENewContactRoleTrigger on PENewContactRole__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewContactRole__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromOppContactRoles(idsUpdateLastActivity);
}