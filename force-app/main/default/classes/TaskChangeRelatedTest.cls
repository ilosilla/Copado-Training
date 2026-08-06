@isTest
public class TaskChangeRelatedTest {
	@TestSetup static void makeData(){
        TestUtils.enableTriggers();
        
        Insert Account_TestDataFactory.createBusinessAccount();
        Insert Account_TestDataFactory.createFabricator();
        DataFactoryLead.createUSWebRequest(1);
        
        Lead aux = [SELECT Id from Lead LIMIT 1];
        aux.Status = 'Not contacted';
        update aux;
        
        List<Account> accList = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1' OR Name = 'TestAcctFabricatorAccount1'];
            
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(Opportunity_TestDataFactory.createTrade(accList[0]));
        oppList.add(Opportunity_TestDataFactory.createTrade(accList[1]));

        insert oppList;    
    }
    
    @isTest
    private static void changeLeads() {
        Lead aux = [SELECT Id, Source__c from Lead LIMIT 1];
        Task newTask = new Task(TaskSubType = 'Email', WhoId = aux.Id, Subject = 'Test');
        insert newTask;
        
        aux = [SELECT Id, Status from Lead LIMIT 1];
        System.assert(aux.Status == 'Contacted via Email', 'Status hasnt changed');
        
        newTask = new Task(TaskSubType = 'Call', WhoId = aux.Id, Subject = 'Test');
        insert newTask;
        
        aux = [SELECT Id, Status from Lead LIMIT 1];
        System.assert(aux.Status == 'Contacted via Phone', 'Status hasnt changed');
    }
    
    @isTest
    private static void changeAccounts() {
        Account aux = [SELECT Id, Last_Activity_Date__c from Account LIMIT 1];
        aux.Last_Activity_Date__c = aux.Last_Activity_Date__c.addDays(-3);
        update aux;
        Datetime beforeTask = aux.Last_Activity_Date__c;
        Test.startTest();
        Task newTask = new Task(TaskSubType = 'Call', WhatId = aux.Id, Subject = 'Test');
        insert newTask;
        Test.stopTest();
        
        aux = [SELECT Id, Last_Activity_Date__c from Account LIMIT 1];
        Datetime afterTask = aux.Last_Activity_Date__c;

        System.assert(beforeTask < afterTask, 'Account Activity Date not updated');
    }
    
    @isTest
    private static void changeOpportunities() {
        Opportunity aux = [SELECT Id, Last_Activity_Date__c from Opportunity LIMIT 1];
        aux.Last_Activity_Date__c = aux.Last_Activity_Date__c.addDays(-3);
        update aux;
        Datetime beforeTask = aux.Last_Activity_Date__c;
        Test.startTest();
        Task newTask = new Task(TaskSubType = 'Call', WhatId = aux.Id, Subject = 'Test');
        insert newTask;
        Test.stopTest();
        
        aux = [SELECT Id, Last_Activity_Date__c from Opportunity LIMIT 1];
        Datetime afterTask = aux.Last_Activity_Date__c;

        System.assert(beforeTask < afterTask, 'Opportunity Activity Date not updated');
    }
}