/**
* @author Ivan Losilla
* @date January 2022
* @group Triggers
* @description Manages the Opportunity Contact Roles Trigger
*/
public class OpportunityContactRoleTriggerHandler extends BaseTriggerHandler {
    
    public override void afterInsert(List<SObject> newItems) {
        Set<Id> listOpportunities = new Set<Id>();
        for (OpportunityContactRole elem: (List<OpportunityContactRole>) newItems) {
            listOpportunities.add(elem.opportunityId);
        }

        if (UserCommons.hasSAPConnection() &&  !System.isFuture()) {
            AutomaticContactRolesSendToSap.manageSendToSap((List<OpportunityContactRole>) newItems);
        }
        platformEventNew((List<OpportunityContactRole>) newItems);

        if (!System.isFuture()) {
            OpportunitiesDomain.setOpportunitySalesProgram(listOpportunities);
        }
    } // afterInsert

    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        if (UserCommons.hasSAPConnection() && !System.isFuture()) {
            AutomaticContactRolesSendToSap.manageSendToSap((List<OpportunityContactRole>) newItems);
        }
    } // afterUpdate

    public override void afterDelete(List<SObject> oldItems) {
        Set<Id> listOpportunities = new Set<Id>();
        for (OpportunityContactRole elem: (List<OpportunityContactRole>) oldItems) {
            listOpportunities.add(elem.opportunityId);
        }

        Set<Id> listOpps = new Set<Id>();
        if (UserCommons.hasSAPConnection() && !System.isFuture()) {
            for (OpportunityContactRole elem: (List<OpportunityContactRole>) oldItems) {
                listOpps.add(elem.OpportunityId);
            }
            for (Id oppId : listOpps) {
                SAPSyncOpportunity.sync(oppId);
            }
        }

        if (!System.isFuture()) {
            OpportunitiesDomain.setOpportunitySalesProgram(listOpportunities);
        }
    } // afterUpdate

    /**
    * @description Creates Platform Events about the new contact
    */
    private void platformEventNew(List<OpportunityContactRole> contactRoles) {
        List<PENewContactRole__e> listPlatformEvents = new List<PENewContactRole__e>();
        for (OpportunityContactRole ctRole : contactRoles) {
            listPlatformEvents.add( new PENewContactRole__e( objectId__c = ctRole.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Opp Contact Role".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}