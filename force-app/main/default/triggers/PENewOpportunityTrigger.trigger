trigger PENewOpportunityTrigger on PENewOpportunity__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    Set<Id> idsOpportunity = new Set<Id>();
    for (PENewOpportunity__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
        idsOpportunity.add(pe.ObjectId__c);
    }
    List<Opportunity> oppsList = new OpportunitiesSelector().selectById(idsOpportunity);

    ActivityDateService.updateFromOpportunities(idsUpdateLastActivity);
    OpportunityMails.alertNotValidCreation(idsUpdateLastActivity);

}