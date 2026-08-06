trigger EmailMessageTrigger  on EmailMessage (before insert, before update, before delete, after insert, after update, after delete) 
{
    // TriggerFactory.createHandler(EmailMessage.sObjectType);
    zflib_TriggerDomainClass.triggerHandler(EmailMessagesDomain.class);
}