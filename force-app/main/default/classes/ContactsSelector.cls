/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Contacts
* @description 	contacts selector class
*/
public class ContactsSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Contact.sObjectType;
    }

    public List<Contact> selectById(Set<Id> recordIds){
        return (List<Contact>) selectSObjectsById(recordIds);
    }

    public Contact selectById(Id recordId){
        List<Contact> listContacts = (List<Contact>) selectSObjectsById(new Set<Id>{recordId});
        if (listContacts.size() == 1) {
            return listContacts[0];
        }
        return null;
    }

    public List<Contact> selectByAccountId(Set<Id> recordIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('AccountId IN :recordIds');
        return (List<Contact>) Database.query( query.toSOQL() );
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            Contact.Id,
            Contact.OwnerId,
            Contact.CurrencyIsoCode,
            Contact.AccountId,
            Contact.Name,
            Contact.Email,
            Contact.Phone,
            Contact.RecordTypeId,

            //Classification fields
            Contact.Dealer__c,
            Contact.Inactive_Contact__c,
            Contact.Specialization__c,
            Contact.ToMarketingCloud__c,

            // Address fields
            Contact.MailingAddress,
            Contact.MailingCity,
            Contact.MailingCountryCode,
            Contact.MailingPostalCode,
            Contact.MailingStateCode,
            Contact.MailingStreet,

            // Admin fields
            Contact.CreatedById,
            Contact.CreatedDate,
            Contact.LastModifiedById
        };
    }
}