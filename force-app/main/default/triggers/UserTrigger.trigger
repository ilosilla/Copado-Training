trigger UserTrigger on User (after delete, after insert, 
                                   after update, before delete, 
                                   before insert, before update){
 
    List<Trigger_configuration__c> tc = Trigger_configuration__c.getall().values();

    if (tc.size() == 0 && Test.isRunningTest()) {
        TriggerFactory2.createAndExecuteHandler(UserHandler.class);
        return;
    } else {                                        
        if (tc[0].User__c == true) {
            TriggerFactory2.createAndExecuteHandler(UserHandler.class);
        }
    }
}