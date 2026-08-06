/**
* @author Ivan Losilla
* @date January 2025
*
* @group Events 
* @description Class controller for the LWC eventRelatedContacts 
*/
public class EventContactsController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(Id eventId) {
        return [SELECT Id, Name, Email, Phone, AccountId, Account.Name FROM Contact WHERE Id IN (SELECT RelationId from EventRelation WHERE EventId =: eventId AND IsWhat = false)];
    }
}