trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update, before insert, before update) {
    zflib_TriggerDomainClass.triggerHandler(AccountContactRelationsDomain.class);
}