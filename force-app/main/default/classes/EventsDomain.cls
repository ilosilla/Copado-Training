/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Events
* @description 	Events domain class
*/
public class EventsDomain extends zflib_TriggerDomainClass {

    public EventsDomain() {
        super();
    }

    public EventsDomain(List<Event> events) {
        super(events);
    }

    public override zflib_TriggerDomainClass cast() {
        return (EventsDomain) this;
    } 

    public override Type getSObjectType() {
        return EventsDomain.class;
    }

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/
    public override void onBeforeInsert() {
        checkCanBeCreated();
        updateStandardType();
        sendAppointmentEmail();
        WeeklyManagementController.eventsSetCompleted((List<Event>)this.Records);
    } //onBeforeInsert

    public override void onAfterInsert() {
        platformEventNew();
        FollowService.eventsCreated((List<Event>) this.Records);
    } //onBeforeInsert

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {        
        updateStandardType();
        WeeklyManagementController.eventsSetCompleted((List<Event>)this.Records);
    } // onBeforeUpdate

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        FollowService.eventsUpdated((List<Event>) this.Records);
    } //onAfterUpdate

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /**
    * @description An event cannot be created if the Account related is locked or deleted
    */
    private void checkCanBeCreated() {
        Schema.SObjectType accountType = Schema.Account.SObjectType;
        Set<Id> listAccountsIds = new Set<Id>();
        Map<Id,SObject> mapAccounts = new Map<Id,SObject>();

        for (Event evt : (List<Event>)this.Records) {
            if( evt.WhatId != null && evt.WhatId.getSObjectType() == accountType){
                listAccountsIds.add(evt.WhatId);
            }
        }

        List<Account> listAccs = new AccountsSelector().selectById(listAccountsIds);
        mapAccounts = TypeConversionCommons.listToMap(listAccs);

        for (Event evt : (List<Event>)this.Records) {
            if(mapAccounts.containsKey(evt.WhatId)){
                Account acc = (Account) mapAccounts.get(evt.WhatId);
                if(acc.Is_Locked__c == true || acc.Is_Deleted__c == true){
                    evt.addError(Label.Cant_Insert_Event);
                }
            }
        }
    }

    private void updateStandardType() {
        for (Event event : (List<Event>)this.Records) {
            event.Type = event.EventType__c;
        }
    }

    /**
     * @description Sends an Email about the appointment to the owner
     */
    private void sendAppointmentEmail() {
        Set<Id> leadIds = new Set<Id>();
        List<Lead> leads = new List<Lead>();
        List<Event> events = new List<Event>();

        if (SystemSettings.USNotifyWebLeads) {
            for (Event event : (List<Event>)this.Records) {
                if (String.isNotBlank(event.WhoId) && event.WhoId.getSObjectType().getDescribe().getName().toUpperCase() == 'LEAD' &&
                    String.isNotBlank(event.Event_type__c) &&
                    ( event.Event_type__c.toUpperCase() == 'SHOWROOM' || event.Event_type__c.toUpperCase() == 'VIRTUAL')) {
                        events.add(event);
                }
                    
                if (events.size() > 0) {
                    LeadsService.sendAppointmentEmail(events);
                }
            }
        }
        
    }

    /**
    * @description Creates Platform Events about the new event
    */
    private void platformEventNew() {
        List<PENewEvent__e> listPlatformEvents = new List<PENewEvent__e>();
        for (Event evt : (List<Event>) this.Records) {
            listPlatformEvents.add( new PENewEvent__e( objectId__c = evt.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Event".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}