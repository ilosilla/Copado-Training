trigger PENewInstallationRequestTrigger on PENewInstallationRequest__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewInstallationRequest__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }
    List<InstallationRequest__c> oppsList = new InstallationRequestsSelector().selectById(idsUpdateLastActivity);

    ActivityDateService.updateFromInstallationRequests(idsUpdateLastActivity);
}