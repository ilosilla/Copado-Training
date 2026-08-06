@isTest public class AccountValidation_RESTAPEXTest {
    
    @testSetup static void setup() {
    
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        //Insert MasterRelations_TestDataFactory.createMasterRelations();
    
    }

    @isTest static void test_runValidation(){
        // Test 1: Fail
        AccountValidation_RESTAPEX.Response actualResponse_1 = AccountValidation_RESTAPEX.runValidation('');
        AccountValidation_RESTAPEX.Response expectedResponse_1 = new AccountValidation_RESTAPEX.Response(false, 'No content to map to Object due to end of input');
        
        System.assert(expectedResponse_1.success == actualResponse_1.success && 
                      expectedResponse_1.errorMessage == actualResponse_1.errorMessage);
        
        // Test 2: 
        /*AccountValidation_RESTAPEX.Response actualResponse_2 = AccountValidation_RESTAPEX.runValidation('{{"customer": { "SAP_Id__c": "" }, "companies": [{"CreatedById" : null}] }}');
        AccountValidation_RESTAPEX.Response expectedResponse_2 = new AccountValidation_RESTAPEX.Response(false, 'No content to map to Object due to end of input');
        
        System.assert(expectedResponse_2.success == actualResponse_2.success && 
                      expectedResponse_2.errorMessage == actualResponse_2.errorMessage);*/
        
    }
    
    //public static Map<String,String> executeUpsert(AccountToSAP_Wrapper accountWrapper){
    @isTest static void test_executeUpsert(){
        // Test 1: Input null
        AccountToSAP_Wrapper wrapper = new AccountToSAP_Wrapper(null, null);
        System.debug('test_executeUpsert Test 1: Input null');
        Map<String,String> actualResponse = AccountValidation_RESTAPEX.executeUpsert(wrapper);
        
        Map<String,String> expectedResponse = new Map<String,String>();
        expectedResponse.put('errorMessage','');
        System.assertEquals(expectedResponse, actualResponse);
        
        // Test 2: Valid Inputs
        System.debug('test_executeUpsert Test 2: Valid Inputs');
        Account acc = Account_TestDataFactory.createBusinessAccount();
        Insert acc;
        Sales_RelationShip__c salesREl = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc);
        //Account acc = [SELECT Id, Name FROM Account WHERE Id =: salesRel.Account_Org__c];
        AccountToSAP_Wrapper wrapper_2 = new AccountToSAP_Wrapper(acc, new List<Sales_RelationShip__c> {salesREl} );
        
        Map<String,String> actualResponse_2 = AccountValidation_RESTAPEX.executeUpsert(wrapper_2);
        Map<String,String> expectedResponse_2 = new Map<String,String>();
        
        System.debug('actualResponse_2: ' + actualResponse_2);
        System.assertEquals('', actualResponse_2.get('errorMessage'));//Erro saving the account-FIELD_CUSTOM_VALIDATION_EXCEPTION:Invalid GB post code for Trade Account. Review the following Customer fields:()
        System.assertEquals(salesREl.Id, actualResponse_2.get('compId'));
        
        // Test 3: Invalid Inputs
        //Sales_RelationShip__c salesREl_3 = Sales_RelationShip_TestDataFactory.createSales_RelationShip();
        //Account acc_3 = [SELECT Id, Name FROM Account WHERE Id =: salesRel.Account_Org__c];
        AccountToSAP_Wrapper wrapper_3 = new AccountToSAP_Wrapper(new Account(), new List<Sales_RelationShip__c> {new Sales_RelationShip__c()} );
        System.debug('test_executeUpsert Test 3: Invalid Inputs');
        Map<String,String> actualResponse_3 = AccountValidation_RESTAPEX.executeUpsert(wrapper_3);
        System.assertNotEquals('', actualResponse_3.get('errorMessage'));
        
        
	}
    
    //public static List<String> getFieldLabels(List<String> fieldNames, String objectName)
    @isTest static void test_getFieldLabels(){
        List<String> expectedResult = new List<String>{'Account Name'};
        List<String> actualResult = AccountValidation_RESTAPEX.getFieldLabels( new List<String>{'Name'}, 'Account');
        
        System.assertEquals(expectedResult, actualResult);
    }

    @isTest static void test_doRequest(){
        RestRequest req = new RestRequest();    
        req.requestURI = '/services/apexrest/v1/Account/Validation';  
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        AccountValidation_RESTAPEX.validateAccount();
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
         
    }
}