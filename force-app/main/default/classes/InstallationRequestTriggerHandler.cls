/**
* @author Ramón Prades
* @date August 2020
*
* @group Installation Request Trigger
* @group-content ../../ApexDocContent/InstallationRequest.htm
*
* @description 
*/
public class InstallationRequestTriggerHandler extends BaseTriggerHandler {
            
    /**
     * @description 			Validates the intallation request can be deleted
     * @param 		oldItems	A Map with the ids and th objects being deleted
     */    
    public override void beforeDelete(List<SObject> oldItems) {
        this.checkInstallationOrders(oldItems);
    } // beforeDelete

    /**
     * @description 			Validates the intallation request can be deleted
     * @param 		oldItems	A List/Map with the ids and th objects being deleted
     */    
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        for (InstallationRequest__c newRequest :(List<InstallationRequest__c>) newItems) {
            InstallationRequest__c oldRequest = (InstallationRequest__c) oldItems.get(newRequest.Id);
            this.setTransitionFields(newRequest, oldRequest.State__c);
        }        
    } // beforeUpdate

    /**
     * @description 			Validates the intallation request can be deleted
     * @param 		oldItems	A List/Map with the ids and th objects being deleted
     */    
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        InstallationMails.changeStateInsrMail((List<InstallationRequest__c>) oldItems.values(), (List<InstallationRequest__c>) newItems);
    } // beforeUpdate 
    
    public override void beforeInsert(List<SObject> newItems) {    
		for (InstallationRequest__c newRequest :(List<InstallationRequest__c>) newItems) {
			this.setTransitionFields(newRequest, '');
        }        
    } // beforeInsert
    
    public override void afterInsert(List<SObject> newItems) {
        platformEventNew((List<InstallationRequest__c>) newItems);
        List<OpportunityTeamMember> installers = this.setOpportunityTeamMember(newItems);
        upsert installers;
    } // afterInsert
    
	/*********************************************************************************************/    
    /********************************       Private Methods      *********************************/
    /*********************************************************************************************/
    private List<OpportunityTeamMember> setOpportunityTeamMember(List<InstallationRequest__c> requests) {
        List<OpportunityTeamMember> members = new List<OpportunityTeamMember>();
        for (InstallationRequest__c request :requests){
            Id userId = UserAccountUtil.getUser(request.InstallerAccount__c, 'INSTALLER');
            if (userId != null) {
                OpportunityTeamMember member = new OpportunityTeamMember();
                member.OpportunityId = request.Opportunity__c;
                member.TeamMemberRole = 'Installer';        
                member.UserId = userId;
                members.add(member);                
            }
        }     
        return members;
    } // setOpportunityTeamMember
    
	/*
	 * Sets fields related to state transtitions
	 */
    private void setTransitionFields(InstallationRequest__c request, String oldState) {
        if ((request.State__c == oldState)) {
            return;
        } else {
            if (InstallationUtil.isRequestAccepted(request)) {
	        	this.setAcceptedFields(request);
        	} 
            if (oldState == InstallationUtil.rejectedState) {
	        	request.ReasonRejected__c = null;
			}
    	}
        request.LastTransition__c = Date.today();
    } // setTransitionFiends    
    
    /*
     * Sets fields related to the installer accepting the request
     */
    private void setAcceptedFields(InstallationRequest__c request) {
        if (InstallationUtil.isRequestAccepted(request)) {
            request.AcceptedBy__c = UserInfo.getUserId();
            request.AcceptedDate__c = Date.today();        
        }
    } // setAcceptedFields
    
    /*
     * Checks the requests do not have any installation order
     */
    private Boolean checkInstallationOrders(List<SObject> oldItems) {
        
        Boolean hasErrors = false;

        Map<Id, Integer> mapOrders = this.getMapOfOrders(oldItems);

        for(InstallationRequest__c request :(List<InstallationRequest__c>) oldItems) {
            Integer numOrders = mapOrders.get(request.Id);      
            if (numOrders > 0) {
                hasErrors = true;
                request.addError(System.Label.insr_error_delete);   
            }
        }        
        return hasErrors;
    } // checkInstallationOrders
    
    /*
     * Returns a map with the rquest Id and tyhe number of orders 
     */
    private Map<Id, Integer> getMapOfOrders(List<InstallationRequest__c> requests) {
        List<Id> ids = new List<Id>();
        for (InstallationRequest__c request :requests) {
            ids.add(request.Id);
        }        
        AggregateResult[] results = [SELECT Installation_Request__c, count(Id) theCount
                           	FROM InstallationOrder__c 
                           	WHERE Installation_Request__c in :ids
						  	GROUP BY Installation_Request__c];
        Map<Id, Integer> theMap = new Map<Id, Integer>();
        for (Integer i = 0; i < results.size(); i++) {
            theMap.put((Id)results[i].get('Installation_Request__c'), (Integer)results[i].get('theCount'));
        }
       return theMap;
    } // getMapOfOrders    

    /**
    * @description Creates Platform Events about the new installation request
    */
    private void platformEventNew(List<InstallationRequest__c> installations) {
        List<PENewInstallationRequest__e> listPlatformEvents = new List<PENewInstallationRequest__e>();
        for (InstallationRequest__c opp : installations) {
            listPlatformEvents.add( new PENewInstallationRequest__e( objectId__c = opp.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Installation Request".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
    
}