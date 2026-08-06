@isTest
public class EventsDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        List<Account> accts = DataFactoryAccount.createAccounts(5);
        for (Account acc : accts) {
            acc.BillingPostalCode = 'LA22 9NZ';
        }
        update accts;
    } // setup
    
    @isTest
    public static void afterInsert(){
       
        Account acc = [SELECT Id, Name, Last_Activity_Date__c,LastEventDateTime__c FROM Account][0];
        acc.Last_Activity_Date__c.addDays(-10);
        acc.LastEventDateTime__c = acc.Last_Activity_Date__c;
        DateTime beforeActivityDate = acc.LastEventDateTime__c;
        update acc;

        Contact ct = new Contact(AccountId = acc.Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
        
        Test.startTest();
        ct = [SELECT Id, Name FROM Contact][0];
        Event ev = new Event(WhatId = acc.Id, StartDateTime = System.now(), EndDateTime = System.now().addDays(8), WhoId = ct.Id, Subject = 'Test Event', Description = 'Desc Test');
        insert ev;
        Test.stopTest();
        
        new EventsDomain(new List<Event>{ev});
        acc = [SELECT Id, Name, LastEventDateTime__c, Last_Activity_Date__c FROM Account where Id =: acc.Id][0];
        System.debug(acc.Last_Activity_Date__c);
        System.debug(acc.LastEventDateTime__c);
        System.assert(acc.LastEventDateTime__c != beforeActivityDate, 'Last Event Date hasn\'t changed');
        System.assert(acc.Last_Activity_Date__c != beforeActivityDate, 'Last Activity Date hasn\'t changed');
        System.assert(acc.Last_Activity_Date__c.date() == acc.LastEventDateTime__c.date(), 'Last Activity are not the same value');

        ev.Subject = 'Test Event 2';
        update ev;

    }
}