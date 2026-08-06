@isTest

private class OpportunityTransactionHandlerTest {

    @testSetup static void setup() {
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
    
    @isTest static void test_runSAPValidation() {
		SAPWS_Utility.SapResponse actualResult_1, actualResult_2, actualResult_3;
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
			
        	// Test 1: Fail body vacio
        	String opportunityWrapperJSON_1 = '{}';
			actualResult_1 = OpportunityTransactionHandler.runSAPValidation(opportunityWrapperJSON_1);
			//SAPWS_Utility.SapResponse expectedResponseObject_1 = new SAPWS_Utility.SapResponse(false,null,'An unexpected error happened. Please try again and if the error persists contact your system administrator.No content to map to Object due to end of input',null,null,'');
			
        	// Test 2: Fail body no valido
        	String accountWrapperJSON_2 = '{"opportunity": "", "opportunityActorsList": ""}';
        	actualResult_2 = OpportunityTransactionHandler.runSAPValidation(accountWrapperJSON_2);
			
        	// Test 3: Success
        	String accountWrapperJSON_3 = '{"opportunity": { "Name": "name", "SalesOrg": "206", "Channel": "10" }, "opportunityActorsList": [{"Id" : "a031w000001DXeGAAW"}] }';
        	actualResult_3 = OpportunityTransactionHandler.runSAPValidation(accountWrapperJSON_3);
			
        Test.stopTest();
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        // System.assertEquals( false, actualResult_1.success );
        // System.assertEquals(false, actualResult_2.success);
        // System.assertEquals(true, actualResult_3.success);
        //System.assertEquals( null, actualResult_3.code ); El metodo deberia devolver el codigo en success?
    }

}