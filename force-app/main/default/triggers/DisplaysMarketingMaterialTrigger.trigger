trigger DisplaysMarketingMaterialTrigger on Displays_Marketing_Material__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // TriggerDispatcher.run(new DisplaysMaterialTriggerHandler());
    zflib_TriggerDomainClass.triggerHandler(DisplaysMarketingMaterialsDomain.class);
}