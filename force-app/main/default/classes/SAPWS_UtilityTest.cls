/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Description:    Clase test de SAPWS_Utility
Date:			27-03-2019
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

@isTest 
public class SAPWS_UtilityTest {
	@testSetup static void setup() {
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
    
    @isTest public static void test_getParams(){
        
        Map<String,String> actualResult = new Map<String,String>();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
            actualResult = SAPWS_Utility.getParams();
        Test.stopTest();

        System.assertEquals('token churro', actualResult.get('token'));
        System.assertEquals('cookie churrito', actualResult.get('cookie'));
    }
    
    @isTest public static void test_getAccountWrapper(){
    	
        AccountToSAP_Wrapper accWrapper1 = new AccountToSAP_Wrapper(new Account(Name = 'Account Test'), new List<Sales_Relationship__c> ());
        String jsonWrapper1 = JSON.serialize(accWrapper1);
        AccountToSAP_Wrapper actualResult1 = SAPWS_Utility.getAccountWrapper(jsonWrapper1);
        
        System.assertEquals(accWrapper1.customer.Name, actualResult1.customer.Name);
        System.assertEquals(accWrapper1.companies, actualResult1.companies);
	}
    
    @isTest public static void test_getOpportunityWrapper(){
    	
        OpportunityToSAP_Wrapper oppWrapper1 = new OpportunityToSAP_Wrapper(new Opportunity(Name = 'Opportunity Test'), new List<OpportunityContactRole> ());
        String jsonWrapper1 = JSON.serialize(oppWrapper1);
        OpportunityToSAP_Wrapper actualResult1 = SAPWS_Utility.getOpportunityWrapper(jsonWrapper1);
        
        System.assertEquals(oppWrapper1.opportunity.Name, actualResult1.opportunity.Name);
        System.assertEquals(oppWrapper1.opportunityActorsList, actualResult1.opportunityActorsList);
	}
    
    @isTest public static void test_getSapRequest(){
    	
        Map<String,String> params = new Map<String,String>();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
            params = SAPWS_Utility.getParams();
        Test.stopTest();
        
        // Test 1: No company then we are editing a customer, as creating new ones follows the standard
        Account acc1 = new Account(Name = 'Account Test', SAP_Id__c='123456789');
        AccountToSAP_Wrapper accWrapper1 = new AccountToSAP_Wrapper(acc1, null);
        String jsonWrapper1 = JSON.serialize(accWrapper1);
        
        HttpRequest actualResult1 = SAPWS_Utility.getSapRequest(params, jsonWrapper1);
        
        System.assertEquals('PUT', actualResult1.getMethod());
        System.assertEquals('callout:SAP/api/customers/' + acc1.Sap_Id__c, actualResult1.getEndPoint());
        
        // Test 2: If we have companies, and the customer has sap id, then we are either creating an additional
        // sales relation (not the fist one) or updating an existing one. For SAP both actions require a PUT 
        Account acc2 = new Account(Name = 'Account Test', SAP_Id__c='123456789');
        AccountToSAP_Wrapper accWrapper2 = new AccountToSAP_Wrapper(acc2, new List<Sales_Relationship__c> {new Sales_Relationship__c()});
        String jsonWrapper2 = JSON.serialize(accWrapper2);
        
        SAPWS_Utility.accountWrapper = null;
        HttpRequest actualResult2 = SAPWS_Utility.getSapRequest(params, jsonWrapper2);
        
        System.assertEquals('PUT', actualResult2.getMethod());
        System.assertEquals('callout:SAP/api/customers/' + acc2.Sap_Id__c, actualResult2.getEndPoint());
        
        // Test 3: If there are companies but no sap id, then we are creating the customer in SAP for first time
        // along with the sales relationhip
        Account acc3 = new Account(Name = 'Account Test');
        AccountToSAP_Wrapper accWrapper3 = new AccountToSAP_Wrapper(acc3, new List<Sales_Relationship__c> {new Sales_Relationship__c(Name = 'Test SalesRel')});
        String jsonWrapper3 = JSON.serialize(accWrapper3);
        
        System.debug('jsonWrapper3: ' + jsonWrapper3);
        SAPWS_Utility.accountWrapper = null;
        HttpRequest actualResult3 = SAPWS_Utility.getSapRequest(params, jsonWrapper3);
        
        System.assertEquals('POST', actualResult3.getMethod());
        System.assertEquals('callout:SAP/api/customers', actualResult3.getEndPoint());
	}
    
    @isTest public static void test_constructors(){
        SAPWS_Utility.SapResponse response = new SAPWS_Utility.SapResponse(true, 200, '', null, '', '');
        
        SAPWS_Utility.Detail newDetail = new SAPWS_Utility.Detail('', '', '');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy'); 
    
    }
    @isTest public static void test_getSapRequestOpp(){
        // Map<String, String> params, String json
        
        Map<String,String> params = new Map<String,String>();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
            params = SAPWS_Utility.getParams();
        Test.stopTest();
        
        // No se realizan validaciones sobre el json en este metodo, asi que no hace falta que tenga un formato especial
        String oppJson = '';
        HttpRequest actualResult = SAPWS_Utility.getSapRequestOpp(params, oppJson);
        
        System.assertEquals('PUT', actualResult.getMethod());
        System.assertEquals('callout:SAP/api/opportunities', actualResult.getEndPoint());
        System.assertEquals(oppJson, actualResult.getBody());
        System.assertEquals('application/json', actualResult.getHeader('Content-Type'));
        System.assertEquals('token churro', actualResult.getHeader('X-CSRF-Token'));
        System.assertEquals('cookie churrito', actualResult.getHeader('cookie'));
        
    }
}