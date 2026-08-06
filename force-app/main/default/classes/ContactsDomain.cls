/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Contacts
* @description 	Contacts domain class
*/
public class ContactsDomain extends zflib_TriggerDomainClass {

    public ContactsDomain() {
        super();
    }

    public ContactsDomain(List<Contact> contacts) {
        super(contacts);
    }

    public override zflib_TriggerDomainClass cast() {
        return (ContactsDomain) this;
    } 

    public override Type getSObjectType() {
        return ContactsDomain.class;
    }

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/

    public override void onAfterInsert() {
        platformEventNew();
    } //onAfterInsert

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        platformEventUpdate(existingRecords);
    } //onAfterUpdate

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /**
    * @description Creates Platform Events about the updated contact
    */
    private void platformEventUpdate(Map<Id,SObject> existingRecords) {
        List<PEUpdateContact__e> listPlatformEvents = new List<PEUpdateContact__e>();
        for (Contact ct : (List<Contact>) this.Records) {
            if (ct.AccountId != ((Contact) existingRecords.get(ct.Id)).AccountId) {
                listPlatformEvents.add( new PEUpdateContact__e( objectId__c = ct.Id, fieldChanged__c = 'AccountId' ));
            }
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "Update Contact".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    }

    /**
    * @description Creates Platform Events about the new contact
    */
    private void platformEventNew() {
        List<PENewContact__e> listPlatformEvents = new List<PENewContact__e>();
        for (Contact ct : (List<Contact>) this.Records) {
            listPlatformEvents.add( new PENewContact__e( objectId__c = ct.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Contact".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew

    public static void updateContactCount(Set<Id> contactsIds) {
        Set<Id> accsIds = new Set<Id>();
        List<Contact> contactsList = new ContactsSelector().selectById(contactsIds);
        Map<Id,Integer> mapAccsContacts = new Map<Id,Integer>();

        for (Contact ct : contactsList) {
            accsIds.add(ct.AccountId);
        }

        List<Contact> allContacts = new ContactsSelector().selectByAccountId(accsIds);
        Integer count = 0;
        for (Contact ct : allContacts) {
            if (mapAccsContacts.containsKey(ct.AccountId) == false) {
                count = 1;
            } else {
                count = mapAccsContacts.get(ct.AccountId) + 1;
            }
            mapAccsContacts.put(ct.AccountId, count);
        }

        List<Account> acctsToUpdate = new AccountsSelector().selectById(mapAccsContacts.keySet());

        for (Account acc : acctsToUpdate) {
            acc.Number_of_Contacts__c = mapAccsContacts.get(acc.Id);
        }

        List<Database.SaveResult> resultsAccounts  = Database.update(acctsToUpdate, false);

        for (Database.SaveResult sr : resultsAccounts) {
            if (!sr.isSuccess()) {
                Logger.warn('Failed update Account Contact Count', sr);
                Logger.saveLog();
            }
        }

    } // updateContactCount
}