/**
* @author Juan Manuel Martinez
*/
@isTest private class NewOpportunity_ControllerTest {
	
    @testSetup static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        insert new Argumentario_Reminder_Days__c(Name = 'Log a Call', NUM_Number_of_days__c = 3);
        User testUser = User_TestDataFactory.createUsers(1, new List<String> {'en_US'})[0];
        insert testUser;
        
        Account acc = Account_TestDataFactory.createCustomer();
        acc.ShippingStreet = 'Test Shipping Street';
        insert acc;
        
        Opportunity opp = Opportunity_TestDataFactory.createEcommerce(acc);
        opp.CloseDate = DATE.today();
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        System.runAs(testUser){
            insert opp;
        }
        Test.stopTest();
        
    }
    
    // Test for method manageMissedCalls(String recordId, Integer numberOfCalls){
    @isTest static void test_manageMissedCalls(){
        Opportunity opp = [SELECT Id, Account.PersonEmail FROM Opportunity LIMIT 1];
        // Test 1: 1 missed call
        Test.startTest();
            String actualResult_1 = NewOpportunity_Controller.manageMissedCalls(opp.Id, 1);
        	String actualResult_2 = NewOpportunity_Controller.manageMissedCalls(opp.Id, 2);
        	//Integer invocations = Limits.getEmailInvocations();    
        Test.stopTest();
        
        //System.assertEquals(1, invocations, 'An email has not been sent');
        System.assertNotEquals(null, actualResult_1);
        
        Task newTask = [SELECT Subject, IsReminderSet, Description, Priority, Status, WhatId, ActivityDate, ReminderDateTime FROM Task WHERE Id =: actualResult_1];
        
        System.assertEquals(true, newTask.IsReminderSet);
        System.assertEquals('Volver a llamar a cliente para consultar satisfacción muestras', newTask.Subject);
        System.assertEquals(true, newTask.IsReminderSet);
        System.assertEquals('Volver a llamar a cliente', newTask.Description);
        System.assertEquals('Normal', newTask.Priority);
        System.assertEquals('Open', newTask.Status);
        System.assertEquals(opp.Id, newTask.WhatId);
        //System.assertEquals( Date.today().addDays(1), newTask.ActivityDate);
        
        //Test 3: invalid number of missed calls
        String actualResult_3 = NewOpportunity_Controller.manageMissedCalls(opp.Id, 3);
        System.assertEquals('else', actualResult_3);
        
        //Test 2: 2 missed calls
        System.assertEquals('Success', actualResult_2);
        //System.assertEquals(opp.Account.PersonEmail, actualResult_2);
        
    }
}