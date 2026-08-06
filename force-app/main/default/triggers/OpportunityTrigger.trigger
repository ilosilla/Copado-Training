/**
* @author Ivan Losilla Perez
* @date January 2021
* @group Triggers
*/

trigger OpportunityTrigger on Opportunity (after insert, after update, before insert, before update) {
        TriggerDispatcher.run(new OpportunityTriggerHandler());
}