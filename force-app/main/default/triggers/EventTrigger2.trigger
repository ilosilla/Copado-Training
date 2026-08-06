/**
* @author Juan Manuel Martinez
* @date March 2019
*
* @group Event
* @group-content ../../ApexDocContent/EventTrigger2.htm
*
* @description No permite crear un nuevo Event si tiene puesto una Account en el campo WhatID 
*				y ésta cuenta se encuentra con el flag bloqueada o borrada a True.
* @deprecated January 2021 - Se utiliza EventTrigger
*/

trigger EventTrigger2 on Event (before insert, after update, after insert) {
	 
//     List<Trigger_configuration__c> tc = Trigger_configuration__c.getall().values();
//     if (tc[0].Event__c == true) {
//         TriggerFactory2.createAndExecuteHandler(EventHandler.class);
//     }
//     else {
//         System.Debug ('Event Triggers OFF');
//     }
}  
// Not working. Modified by Ivan Losilla, so we can use EventTrigger