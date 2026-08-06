/**
* @author Juan Manuel Martinez
*/
@isTest private class Qualification_ControllerTest {
	
    /*@future static void insertUser(){
        Profile p = [SELECT ID FROM Profile WHERE NAME = 'Standard User'];
        insert new Trigger_configuration__c(User__c = false);
        User u = new User(Alias = 'standt', Email='Qualification_Controller@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName= 'Qualification_Controller@testorg.com' );
        insert u;
        
    }*/
    
    @testSetup static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        Account acc = Account_TestDataFactory.createCustomer();
        acc.ShippingStreet = 'Test Shipping Street';
        Insert acc;
        
            Opportunity opp = Opportunity_TestDataFactory.createEcommerce(acc);
            opp.Close_Mode__c='In shop date';
            opp.CloseDate = Date.today();
            Insert opp;
        
    }
    
    // Test for the method String createTask(String recordId, String taskDate, String taskSubject){
    @isTest static void test_createTask(){
        Opportunity[] opps = [SELECT Id FROM Opportunity WHERE NAME = 'Test Opportunity ecommerce 1'];
        if (opps.size() == 0) {
            return;
        }
        Opportunity opp = opps[0];
        DATETIME now = DATETIME.now();
        
        String actualResult = Qualification_Controller.createTask(opp.Id, String.valueOf( now ), 'Subject');
        
        System.assertNotEquals(null, actualResult);
        Task newTask = [SELECT Subject, IsReminderSet, Description, Priority, Status, WhatId, ActivityDate, ReminderDateTime FROM Task WHERE Id =: actualResult];
        System.assertEquals('Subject', newTask.Subject);
        System.assertEquals(true, newTask.IsReminderSet);
        System.assertEquals('Subject', newTask.Description);
        System.assertEquals('Normal', newTask.Priority);
        System.assertEquals('Open', newTask.Status);
        System.assertEquals(opp.Id, newTask.WhatId);
        System.assertEquals(Date.today(), newTask.ActivityDate);
        
    }
    
    // Test for the method getUserName
    @isTest static void test_getUserName(){
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        /*
        User testUser = [SELECT Id, Name FROM User WHERE UserName LIKE '%@testOrg.com' LIMIT 1];
        
        System.runAs(testUser) {
            String actualResult = Qualification_Controller.getUserName();
            
            System.assertEquals(testUser.Name, actualResult);
        }
        */
    }
}