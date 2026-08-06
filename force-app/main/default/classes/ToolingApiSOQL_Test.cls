@isTest
public class ToolingApiSOQL_Test {
	
    @testSetup static void setup() {
        
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        // Create common test accounts
        insert Account_TestDataFactory.createFabricator();
        
    }
    
    @isTest public static void test_restGet(){
        Account acc = [SELECT Id, RecordTypeId FROM Account WHERE Name = 'TestAcctFabricatorAccount1' LIMIT 1];
        String actualResult_1;
        // PageLayoutMockHttpResponseGenerator es un mock para la llamada a tooling api.
        // Devuelve siempre el nombre "LayoutForTesting-Edition Layout"
        Test.setMock(HttpCalloutMock.class, new PageLayoutMockHttpResponseGenerator());
        Test.startTest();
        	actualResult_1 = ToolingApiSOQL.getLayoutNameForCurrentUserProfile(acc.Id, acc.RecordTypeId); 
        Test.stopTest();
        
        System.assertEquals('LayoutForTesting-Edition Layout', actualResult_1);
    }
    
}