trigger PENewContactTrigger on PENewContact__e (after insert) {
    System.debug('-------------------------');
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewContact__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromContacts(idsUpdateLastActivity);
    System.debug('*******************');
    System.debug(idsUpdateLastActivity);
    ContactsDomain.updateContactCount(idsUpdateLastActivity);
}