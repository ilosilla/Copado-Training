trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (before insert, before update, before delete, after insert, after update, after delete)
{
	// TriggerDispatcher.run(new OpportunityTeamMemberTriggerHandler());
    zflib_TriggerDomainClass.triggerHandler(OpportunityTeamMembersDomain.class);

}