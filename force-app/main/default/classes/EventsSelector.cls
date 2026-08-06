/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Events
* @description 	events selector class
*/
public class EventsSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Event.sObjectType;
    }

    public List<Event> selectById(Set<Id> recordIds){
        return (List<Event>) selectSObjectsById(recordIds);
    }

    public Event selectById(Id recordId){
        List<Event> listEvents = (List<Event>) selectSObjectsById(new Set<Id>{recordId});
        if (listEvents.size() == 1) {
            return listEvents[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            Event.Id,
            Event.CurrencyIsoCode,
            Event.OwnerId,
            Event.Description,
            Event.Subject,
            
            //Classification fields
            Event.IsAllDayEvent,
            Event.Type,
            Event.EventSubtype,
            Event.IsPrivate,
            Event.Event_Subtype__c,
            
            // Other info fields
            Event.WhoId,
            Event.WhatId,
            Event.AccountId,

            // Admin fields
            Event.CreatedById,
            Event.CreatedDate,
            Event.ActivityDate,
            Event.LastModifiedById
        };
    }
}