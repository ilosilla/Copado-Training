trigger AccountTeamMemberTrigger on AccountTeamMember (before insert, before update, before delete, after insert, after update, after delete)
{
	// TriggerDispatcher.run(new AccountTeamMemberTriggerHandler());
	zflib_TriggerDomainClass.triggerHandler(AccountTeamMembersDomain.class);
}