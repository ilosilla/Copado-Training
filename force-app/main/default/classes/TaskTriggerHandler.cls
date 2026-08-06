/**
* @author Ivan Losilla
* @date September 2021
* @group Triggers
* @description Manages the Task Trigger
*/
public class TaskTriggerHandler extends BaseTriggerHandler {
    /**
     * @description 			Validates the intallation request can be deleted
     * @param 		oldItems	A List/Map with the ids and th objects being deleted
     */    
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        TaskChangeRelated.changeAccounts((List<Task>) newItems, 'UPDATE');
        TaskChangeRelated.changeOpportunities((List<Task>) newItems, 'UPDATE');
        FollowService.tasksUpdated((List<Task>) newItems);
    } // beforeUpdate 
    
    public override void beforeInsert(List<SObject> newItems) {
        canBeCreated((List<Task>) newItems);    
    } // beforeInsert
    
    public override void afterInsert(List<SObject> newItems) {
        TaskChangeRelated.changeAccounts((List<Task>) newItems, 'INSERT');
        TaskChangeRelated.changeOpportunities((List<Task>) newItems, 'INSERT');
        TaskChangeRelated.changeLeads((List<Task>) newItems, 'INSERT');
        FollowService.tasksCreated((List<Task>) newItems);
        platformTaskNew((List<Task>) newItems);
    } // afterInsert

    
	/*********************************************************************************************/    
    /********************************       Private Methods      *********************************/
    /*********************************************************************************************/
    private void canBeCreated(List<Task> tasks) {
        Schema.SObjectType accountType = Schema.Account.SObjectType;
        Set<Id> listAccountsIds = new Set<Id>();
        Map<Id,Account> mapAccounts = new Map<Id,Account>();

        for (Task task : tasks) {
            if( task.WhatId != null && task.WhatId.getSObjectType() == accountType){
                listAccountsIds.add(task.WhatId);
            }
        }

        mapAccounts = new Map<Id,Account>([SELECT Name, Id, Is_Deleted__c, Is_Locked__c FROM Account where Id IN : listAccountsIds]);

        for (Task task : tasks) {
            if(mapAccounts.containsKey(task.WhatId)){
                Account acc = mapAccounts.get(task.WhatId);
                if(acc.Is_Locked__c || acc.Is_Deleted__c){
                    task.addError(Label.Cant_Insert_Event);
                }
            }
        }
    }

    /**
    * @description Creates Platform Events about the new contact
    */
    private void platformTaskNew(List<Task> tasks) {
        List<PENewTask__e> listPlatformEvents = new List<PENewTask__e>();
        for (Task task : tasks) {
            listPlatformEvents.add( new PENewTask__e( objectId__c = task.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Task".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}