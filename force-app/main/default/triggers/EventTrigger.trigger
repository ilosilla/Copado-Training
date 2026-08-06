trigger EventTrigger on Event (before insert, before update, before delete, after insert, after update, after delete)
{
	// TriggerDispatcher.run(new EventTriggerHandler());
    zflib_TriggerDomainClass.triggerHandler(EventsDomain.class);
}