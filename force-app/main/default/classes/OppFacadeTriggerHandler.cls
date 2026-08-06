/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Triggers
* @description 	Trigger handler for OppFacade__c
*/
public class OppFacadeTriggerHandler extends BaseTriggerHandler {
    
    public override void afterInsert(List<SObject> newItems) {
        List<Id> oppIds = new List<Id>();
        List<Id> ids = new List<Id>();
        for (OppFacade__c cp :(List<OppFacade__c>) newItems) {
            ids.add(cp.Id);
            oppIds.add(cp.Opportunity__c);
        }
        OpportunitiesInfoCommons.setOpportunityType(oppIds, OpportunitiesInfoCommons.FACADE_TYPE);
        Logger.setScenario('OPP.FACADE');
        if (SystemSettings.CPNotificationsEnabled) {
            Logger.info('Recordatorio de ficheros programado');
            Logger.saveLog();
            OppFacadeScheduler.scheduleReminder(ids);
            OppFacadeScheduler.scheduleNewFacade(ids);
        }
        if (SystemSettings.CPDeletionTime > 0) {
            Logger.info('Borrado programado para dentro de ' + SystemSettings.CPDeletionTime );
            Logger.saveLog();
            OppFacadeScheduler.scheduleDeletion(ids);
        }
    } // afterInsert

    public override void afterDelete(List<SObject> oldItems) {
        List<Id> oppIds = new List<Id>();
        for (OppFacade__c cp :(List<OppFacade__c>) oldItems) {
            oppIds.add(cp.Opportunity__c);
        }        
        OpportunitiesInfoCommons.setOpportunityType(oppIds, null);
    }


} // class