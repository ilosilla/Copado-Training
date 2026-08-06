@isTest
public with sharing class OpportunityContactRolesSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 1);
        List<Contact> contacts = DataFactoryContact.createContacts(accs[0].Id, 2);
        OpportunityContactRole contactRole = new OpportunityContactRole(OpportunityId = opps[0].Id, ContactId = contacts[0].Id);
        insert contactRole;
    }

    @isTest
    private static void selectById() {
        Set<Id> contactRoles = new Set<id>();
        for(OpportunityContactRole l : [Select Id from OpportunityContactRole]) {
            contactRoles.add(l.id);
        }

        List<OpportunityContactRole> result = new OpportunityContactRolesSelector().selectById(contactRoles);
        System.assertEquals(1, result.size(), '1 Contact Role expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        OpportunityContactRole evt = [Select Id from OpportunityContactRole LIMIT 1];
        OpportunityContactRole result = new OpportunityContactRolesSelector().selectById(evt.Id);
        System.assert(result != null, 'No se ha encontrado el Contact Role');
    }
}