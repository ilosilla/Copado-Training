/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:           05-04-2019
Description:    No permite eliminar una cuenta que tenga un sap id asignado
Test Class:     AccountHandlerTest
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

trigger AccountTrigger2 on Account (before delete, before insert, before update, after insert, after update) {
    // List<Trigger_configuration__c> tc = Trigger_configuration__c.getall().values();
    
    // System.debug('tc.size() ' + tc.size());
    
    // if (tc[0].Account__c) {
    //     TriggerFactory2.createAndExecuteHandler(AccountHandler2.class);
    // }
}