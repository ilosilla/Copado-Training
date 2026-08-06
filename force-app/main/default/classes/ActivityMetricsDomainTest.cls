@isTest
public class ActivityMetricsDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(5);
    } // setup

    @isTest
    public static void afterInsert(){
       
        Account acc = [SELECT Id, Name, Last_Activity_Date__c,LastEventDateTime__c FROM Account][0];
        acc.Last_Activity_Date__c.addDays(-10);
        acc.LastEventDateTime__c = acc.Last_Activity_Date__c;
        update acc;

        Contact ct = new Contact(AccountId = acc.Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
        
        Test.startTest();
        ct = [SELECT Id, Name FROM Contact][0];
        Event ev = new Event(WhatId = acc.Id, StartDateTime = System.now(), EndDateTime = System.now().addDays(8), WhoId = ct.Id, Subject = 'Test Event', Description = 'Desc Test');
        insert ev;
        Test.stopTest();

        ActivityMetric aux = new ActivityMetric(BaseId = acc.Id, LastEmailDateTime = System.now());
        insert aux;
        
        // new ActivityMetricsDomain();
        acc = [SELECT Id, Name, LastEmailDateTime__c, Last_Activity_Date__c FROM Account where Id =: acc.Id][0];
        System.assert(acc.LastEmailDateTime__c.date() == acc.Last_Activity_Date__c.date(), 'No se ha actualizado LastEmailDateTime');
        
        aux.LastEmailDateTime.addDays(8);
        update aux;

        new ActivityMetricsDomain(new List<ActivityMetric>{aux});
        
        acc = [SELECT Id, Name, LastEmailDateTime__c, Last_Activity_Date__c FROM Account where Id =: acc.Id][0];
        System.assert(acc.LastEmailDateTime__c.date() == acc.Last_Activity_Date__c.date(), 'No se ha actualizado LastEmailDateTime');
    }
}