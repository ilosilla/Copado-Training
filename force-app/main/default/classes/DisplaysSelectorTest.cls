@isTest
public with sharing class DisplaysSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);
        Displays_Marketing_Material__c display = new Displays_Marketing_Material__c(Account__c = accs[0].Id, Type__c = 'Settings');
        insert display;
    }

    @isTest
    private static void selectById() {
        Set<Id> displaysIds = new Set<id>();
        for(Displays_Marketing_Material__c l : [Select Id from Displays_Marketing_Material__c]) {
            displaysIds.add(l.id);
        }

        List<Displays_Marketing_Material__c> result = new DisplaysSelector().selectById(displaysIds);
        System.assertEquals(1, result.size(), '1 Display expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Displays_Marketing_Material__c evt = [Select Id from Displays_Marketing_Material__c LIMIT 1];
        Displays_Marketing_Material__c result = new DisplaysSelector().selectById(evt.Id);
        System.assert(result != null, 'No se ha encontrado el Display');
    }
}