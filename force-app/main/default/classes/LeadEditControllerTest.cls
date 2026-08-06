@isTest public with sharing class LeadEditControllerTest {

    @isTest static void getContactsTest() {
        Account account = DataFactoryAccount.createAccounts(1)[0];
        DataFactoryContact.createContacts(account.Id, 10);
        List<Contact> contacts = LeadEditController.getContacts(account.Id);
        System.assertEquals(10, contacts.size(), 'Wrong contact list returned');
    }
}