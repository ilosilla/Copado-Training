/*-----------------------------------------------------------------------------------------
Author:         
Company:        Neoris
Date:           
Description:    
Test Class:     Test de la clase AccountTransactionHandler
History
<Date>            <Author>              <Change Description>

-----------------------------------------------------------------------------------------*/
@isTest

private class AccountTransactionHandlerTest {

    @testSetup static void setup() {
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers(); 
    }
    
    /**
     * This is a test method for runTransaction
     
    static testMethod void test_runTransaction() {
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // PageReference pageRef = Page.AccountTransactionHandler;
        // Test.setCurrentPage(pageRef);
        // pageRef.getParameters().put('param1', 'param1');

        Test.startTest();
		
        //CalloutClassTest.testCallout();
		String accountWrapperJSON = 'PhoGw5a';
		AccountTransactionHandler.TransactionResponse resultRunTransaction = AccountTransactionHandler.runTransaction(accountWrapperJSON);

        Test.stopTest();

        // Check
        // System.assert(ApexPages.hasMessages());
        // for(ApexPages.Message msg : ApexPages.getMessages()) {
        //     System.assertEquals('Upload file is NULL', msg.getSummary());
        //     System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
        // }
    }
*/

    /**
     * This is a test method for runSfValidation
     */
    static testMethod void test_runSfValidation() {

        AccountValidation_RESTAPEX.Response resultRunSfValidation;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();

		String accountWrapperJSON = 'cLnfcJ5';
		
        resultRunSfValidation = AccountTransactionHandler.runSfValidation(accountWrapperJSON);
		
        Test.stopTest();
        
        System.debug('resultRunSfValidation: ' + resultRunSfValidation);
        
        System.assertEquals(true, resultRunSfValidation.success);
        System.assertEquals(null, resultRunSfValidation.errorMessage);
        System.assertEquals(null, resultRunSfValidation.sapId);
        
    }


    /**
     * This is a test method for runSAPValidation
     */
    static testMethod void test_runSAPValidation() {
        
        SAPWS_Utility.SapResponse resultRunSAPValidation_1, resultRunSAPValidation_2, resultRunSAPValidation_3, resultRunSAPValidation_4;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        String accountWrapperJSON_1 = '{}';
        resultRunSAPValidation_1 = AccountTransactionHandler.runSAPValidation(accountWrapperJSON_1, 0);
        
        String accountWrapperJSON_3 = '{"customer": { "SAP_Id__c": null }, "companies": [{"CreatedById" : null}] }';
        resultRunSAPValidation_3 = AccountTransactionHandler.runSAPValidation(accountWrapperJSON_3, 0);
        
        String accountWrapperJSON_2 = '{"customer": { "SAP_Id__c": "0001086108" }, "companies": [{"CreatedById" : null}]}';
        resultRunSAPValidation_2 = AccountTransactionHandler.runSAPValidation(accountWrapperJSON_2, 0);
        
        String accountWrapperJSON_4 = '{"customer": "Bad Input"}';
        resultRunSAPValidation_4 = AccountTransactionHandler.runSAPValidation(accountWrapperJSON_4, 0);
        
        Test.stopTest();
        
        System.debug ('resultRunSAPValidation_1: ' + resultRunSAPValidation_1);
        System.assertEquals( false, resultRunSAPValidation_1.success );
        
        System.debug ('resultRunSAPValidation_2: ' + resultRunSAPValidation_2);
        System.assertEquals( true, resultRunSAPValidation_2.success );	
        System.assertEquals( 200, resultRunSAPValidation_2.code );
        
        System.debug ('resultRunSAPValidation_3: ' + resultRunSAPValidation_3);
        System.assertEquals( true, resultRunSAPValidation_3.success );	
        System.assertEquals( 200, resultRunSAPValidation_3.code );	
        
        System.debug ('resultRunSAPValidation_4: ' + resultRunSAPValidation_4);
        System.assertEquals( false, resultRunSAPValidation_4.success );	
        System.assertEquals( 600, resultRunSAPValidation_4.code );
    }

    

    /**
     * This is a test method for all
     */
    static testMethod void test_all() {
		AccountTransactionHandler.TransactionResponse resultRunTransaction, resultRunTransaction_2;
            
        //  test runTransaction
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        String accountWrapperJSON = '{"customer": { "SAP_Id__c": null }, "companies": [{"Relationship__c": "Z4", "CreatedById" : null}] }'; // PhoGw5a
        resultRunTransaction = AccountTransactionHandler.runTransaction(accountWrapperJSON);
        
        String accountWrapperJSON_2 = '{"customer": "Bad Input"}'; // PhoGw5a
        resultRunTransaction_2 = AccountTransactionHandler.runTransaction(accountWrapperJSON_2);
        
        Test.stopTest();
        
        System.debug ('resultRunTransaction: ' + resultRunTransaction);
        System.assertEquals(false, resultRunTransaction.success);
        
        System.debug ('resultRunTransaction_2: ' + resultRunTransaction_2);
        System.assertEquals(false, resultRunTransaction_2.success);

    }
	
}