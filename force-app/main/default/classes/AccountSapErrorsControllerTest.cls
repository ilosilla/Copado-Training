@isTest
public class AccountSapErrorsControllerTest {
    @testSetup static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
                
        // Account con Sales Rel
        Account acc = Account_TestDataFactory.createBusinessAccount();
        Insert acc;
        Sales_Relationship__c salesRelSuccess = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc);
        Insert salesRelSuccess;
        
        Account accFab = Account_TestDataFactory.createFabricator();
        Insert accFab;
        
        Sales_Relationship__c salesRelWithError = Sales_RelationShip_TestDataFactory.createSalesRelationship(accFab);
        salesRelWithError.Relationship__c = null;
        salesRelWithError.Name = 'Test_Sales_Rel_WithError';
        Insert salesRelWithError;
        
        Account accCustomer = Account_TestDataFactory.createCustomer();
        Insert accCustomer;
        
        Sales_Relationship__c salesRelWithError2 = Sales_RelationShip_TestDataFactory.createSalesRelationship(accCustomer);
        salesRelWithError2.Relationship__c = null;
        salesRelWithError2.Name = 'Test_Sales_Rel_WithError2';
        Insert salesRelWithError2;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        Automatic_AccountSendToSAP.SendToSAP( new List<Id>{salesRelWithError.Id, salesRelWithError2.Id, salesRelSuccess.Id});
        	
        Test.stopTest();
        
    }
    
    @isTest public static void test_returnAccErrors(){
        // Test 1: Invalid Record Id
        List<Sales_Relationship__c> actualResutl_1 = AccountSapErrorsController.returnAccErrors('');
        
        System.assertEquals(new List<Sales_Relationship__c>(), actualResutl_1);
        
        AccountSapErrorsController.retry('');        
        
    }
    
}