/**
* @author           Ramón Prades
* @date             Feb 2021
* @group            Triggers
* @description      Trigger handler for leads
*/
trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete){
    // TriggerDispatcher.run(new LeadNewTriggerHandler());
    zflib_TriggerDomainClass.triggerHandler(LeadsDomain.class);
} //trigger