trigger PEUpdateContactTrigger on PEUpdateContact__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PEUpdateContact__e pe : Trigger.New) {
        if (pe.fieldChanged__c.toUpperCase() == 'ACCOUNTID'){
            idsUpdateLastActivity.add(pe.ObjectId__c);
        }
    }

    ActivityDateService.updateFromContacts(idsUpdateLastActivity);
    ContactsDomain.updateContactCount(idsUpdateLastActivity);
}