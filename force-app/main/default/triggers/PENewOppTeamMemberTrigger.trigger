trigger PENewOppTeamMemberTrigger on PENewOppTeamMember__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewOppTeamMember__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromOppTeamMembers(idsUpdateLastActivity);
}