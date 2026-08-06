trigger PENewMoodboard on PENewMoodboard__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewMoodboard__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromMoodboards(idsUpdateLastActivity);
}