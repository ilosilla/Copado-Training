@isTest
public class EventType_Batch_Test {
	@testSetup
    static void setup(){
        
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        List<Event> eventList =  new List<Event>();
        List<Account> accList = new List<Account>();
        
        for(Integer i=0; i<2; i++){
            accList.add(Account_TestDataFactory.createRetailer());
        }
        
        Account_TestDataFactory.insertAccounts(accList);
        
        Account acc = [SELECT Id, Name, Last_Activity_Date__c FROM Account][0];
        Contact ct = new Contact(AccountId = acc.Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
        ct = [SELECT Id, Name FROM Contact][0];
        
        for(Integer i=0; i<2; i++){
            eventList.add(new Event(WhatId = accList[i].Id, Subject='Subject', WhoId=ct.Id, StartDateTime=DateTime.now(), EndDateTime=DateTime.now().addDays(2),
                                   EventType__c = 'Claim Visit'));
        }
        
        Insert eventList;
        
    }
    
    @isTest
    public static void test(){
        Integer numberOfEvents = [SELECT Count() FROM Event];
        
        Test.startTest();
        
        EventType_Batch obj = new EventType_Batch();
        Id batchJobId = DataBase.executeBatch(obj);
        
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                            FROM AsyncApexJob
                            WHERE Id = :batchJobId];
        
        Integer afterCount = [SELECT Count() FROM Event WHERE EventType__c != null];
        
        System.assertEquals(numberOfEvents, afterCount);
        System.assertEquals(job.NumberOfErrors, 0);
        
        
    }
}