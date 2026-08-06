@isTest
public class TaskTriggerHandlerTest {
    @testSetup static void setup() {
		// El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        // Create common test accounts
        Account acc = Account_TestDataFactory.createCustomer();
        Insert acc;
        
        //Insert Opportunity_TestDataFactory.createEcommerce(acc);
        
    }
    
    @isTest
    public static void test_TaskTrigger(){
        // Test 1: Success
        Account acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE LastName = 'TestAcctCustomer1'];
        acc.Last_Activity_Date__c.addDays(-10);
        DateTime beforeDate = acc.Last_Activity_Date__c;
        update acc;
        Task newTask = new Task(WhatId=acc.Id, Priority='Normal', Status='Open', Subject='Call');
        
        test.startTest();
        Database.SaveResult result_test_1 = Database.insert(newTask, false);
        test.stopTest();

		System.assert( result_test_1.isSuccess() );
        acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id =: acc.Id];
        System.assert(acc.Last_Activity_Date__c != beforeDate);
        
        // Test 2: Fail because of deleted account
        acc.Is_Deleted__c = true;
        Update acc;
        
        Task newTask2 = new Task(WhatId=acc.Id, Priority='Normal', Status='Open', Subject='Call');
        Database.SaveResult result_test_2 = Database.insert(newTask2, false);
		System.debug(result_test_2.getErrors()[0].getMessage());
        System.assert( !result_test_2.isSuccess() );
        
        // Test 3: Fail because of locked account
        acc.Is_Deleted__c = false;
        acc.Is_Locked__c = true;
        Update acc;
        
        Task newTask3 = new Task(WhatId=acc.Id, Priority='Normal', Status='Open', Subject='Call');
        Database.SaveResult result_test_3 = Database.insert(newTask3, false);
		System.debug(result_test_3.getErrors()[0].getMessage());
        System.assert( !result_test_3.isSuccess() );
        
        // Test 4: Task with WhatId empty
        Task newTask4 = new Task(Priority='Normal', Status='Open', Subject='Call');
        
        Database.SaveResult result_test_4 = Database.insert(newTask4, false);
        System.assert( result_test_4.isSuccess() );

        // Test 5: Update Task
        Task task = [SELECT Id, Subject FROM Task LIMIT 1];
        task.Subject = 'Email';
        
        Database.SaveResult result_test_5 = Database.update(task, false);
        System.assert( result_test_5.isSuccess() );
    }
}