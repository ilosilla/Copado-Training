@isTest
public with sharing class EventsSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);

        Account acc = [SELECT Id, Name, Last_Activity_Date__c FROM Account][0];
        Contact ct = new Contact(AccountId = acc.Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
        
        Event ev = new Event(WhatId = acc.Id, StartDateTime = System.now(), EndDateTime = System.now().addDays(8), WhoId = ct.Id, Subject = 'Test Event', Description = 'Desc Test');
        insert ev;
    }

    @isTest
    private static void selectById() {
        Set<Id> eventsIds = new Set<id>();
        for(Event l : [Select Id from Event]) {
            eventsIds.add(l.id);
        }

        List<Event> result = new EventsSelector().selectById(eventsIds);
        System.assertEquals(1, result.size(), '1 Events expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Event evt = [Select Id from Event LIMIT 1];
        Event result = new EventsSelector().selectById(evt.Id);
        System.assert(result != null, 'No se ha encontrado el Event');
    }
}