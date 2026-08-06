@isTest
public with sharing class SalesRelationshipsSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);
        DataFactoryAccount.createSalesRelation(accs[0],OrganizationCommons.ORG_SOUTH_EAST,'60','2594');
    }

    @isTest
    private static void selectById() {
        Set<Id> salesRelsIds = new Set<id>();
        for(Sales_Relationship__c l : [Select Id from Sales_Relationship__c]) {
            salesRelsIds.add(l.id);
        }
        List<Sales_Relationship__c> result = new SalesRelationshipsSelector().selectById(salesRelsIds);
        System.assertEquals(1, result.size(), 'Se esperaba una Sales relationship');
    }
    @isTest
    private static void selectByAccountId() {
        Sales_Relationship__c salesRel = [Select Id, Account_Org__c from Sales_Relationship__c LIMIT 1];
        Account acc2 = [Select Id from Account where Id <> : salesRel.Account_Org__c LIMIT 1];

        List<Sales_Relationship__c> result = new SalesRelationshipsSelector().selectByAccountId(new Set<Id>{salesRel.Account_Org__c});
        List<Sales_Relationship__c> result2 = new SalesRelationshipsSelector().selectByAccountId(new Set<Id>{acc2.Id});
        System.assertEquals(1, result.size(), 'Se esperaba una Sales relationship');
        System.assertEquals(0, result2.size(), 'No se esperaba una Sales relationship');
    }

}