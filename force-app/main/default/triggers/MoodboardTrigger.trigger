/**
* @author           Ivan Losilla
* @date             April 2022
* @group            Triggers
* @description      Trigger handler for Moodboard
*/
trigger MoodboardTrigger on Moodboard__c (before insert, before update, before delete, after insert, after update, after delete){
    // TriggerDispatcher.run(new MoodboardTriggerHandler());
    zflib_TriggerDomainClass.triggerHandler(MoodboardsDomain.class);
} //trigger