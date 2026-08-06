trigger OrderTrigger on Order (before insert, before update, before delete, after insert, after update, after delete) {    
    // TriggerDispatcher.run(new OrderTriggerHandler());
    zflib_TriggerDomainClass.triggerHandler(OrdersDomain.class);
}