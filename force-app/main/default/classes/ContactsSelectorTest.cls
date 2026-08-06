@isTest
public with sharing class ContactsSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);
        DataFactoryContact.createContacts(accs[0].Id, 5);
    }

    @isTest
    private static void selectById() {
        Set<Id> contactsIds = new Set<id>();
        for(Contact l : [Select Id from Contact]) {
            contactsIds.add(l.id);
        }

        List<Contact> result = new ContactsSelector().selectById(contactsIds);
        System.assertEquals(5, result.size(), '5 contacts expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Contact ct = [Select Id from Contact LIMIT 1];
        Contact result = new ContactsSelector().selectById(ct.Id);
        System.assert(result != null, 'No se ha encontrado el Contact');
    }

    @isTest
    private static void selectByAccountId() {
        Contact ct = [Select Id, AccountId from Contact LIMIT 1];
        List<Contact> result = new ContactsSelector().selectByAccountId(new Set<Id>{ct.AccountId});
        System.assert(result.size() > 0, 'No se han encontrado Contacts');
        Account acc = [Select Id from Account where Id <> :ct.AccountId LIMIT 1];
        List<Contact> result2 = new ContactsSelector().selectByAccountId(new Set<Id>{acc.Id});
        System.assert(result2.size() == 0, 'Se han encontrado Contacts');
    }

}