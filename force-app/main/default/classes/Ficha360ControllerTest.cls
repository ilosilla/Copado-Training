@isTest
public class Ficha360ControllerTest {
    
    @testSetup static void setup() {
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        User newUser = User_TestDataFactory.createUsers(1, new List<String>{'en_US'})[0]; 
        newUser.Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE + ';' + OrganizationCommons.ORG_SOCAMED;
        newUser.Default_Sales_Organization__c = OrganizationCommons.ORG_AZURCERAMIQUE;
        newUser.Sales_office__c = '3015';
        insert newUser;
        
        System.debug('Usuario: ' + newUser);
        
        Account acc = Account_TestDataFactory.createCustomer();
        acc.Sap_Id__c = '0001086837';
        //acc.Company_List__c = '207';
        //acc.Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE;
        insert acc;
        
        Account acc2 = Account_TestDataFactory.createFabricator();
        acc2.Sap_Id__c = '0001086838';
        //acc2.Company_List__c = '207';
        //acc2.Sales_Org__c = OrganizationCommons.ORG_LORCERAM;
        insert acc2;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        	insert Sales_RelationShip_TestDataFactory.createSalesRelWithPicklist(acc, OrganizationCommons.ORG_AZURCERAMIQUE, '3015', '30');
       		insert Sales_RelationShip_TestDataFactory.createSalesRelWithPicklist(acc2, OrganizationCommons.ORG_LORCERAM, '3015', '30');
        Test.stopTest();
        
        insert Account_TestDataFactory.createBusinessAccount();
    }
    
    @isTest
    public static void test_getSalesOrgs(){
        
        User testUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg0.com' LIMIT 1];
        
        System.runAs(testUser){
            // Test 1: Error. Account sin Sap Id
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
            List<Map<String,String>> actualResult_1 = Ficha360Controller.getSalesOrgs(acc.Id);
            
            System.assert(actualResult_1[0].containsKey('ERROR') );
            System.assertEquals(Label.Ficha360_Credit_Status_Unavaileble, actualResult_1[0].get('ERROR'));
            
            // Test 2: Account con Sap Id. Account con Sales Org que no estan en las Sales Orgs del usuario.
            Account acc2 = [SELECT Id FROM Account WHERE Name = 'TestAcctFabricatorAccount1'];
            List<Map<String,String>> actualResult_2 = Ficha360Controller.getSalesOrgs(acc2.Id);
            
            System.assertEquals('Your user\'s Sales Org doesnt correspond with any of the account\'s Sales Org', actualResult_2[0].get('ERROR'));
            
            // Test 3: Account con Sap Id. Account con Sales Org que no esta en las Sales Orgs del usuario.
            
            Account acc3 = [SELECT Id FROM Account WHERE LastName = 'TestAcctCustomer1'];
            List<Map<String,String>> actualResult_3 = Ficha360Controller.getSalesOrgs(acc3.Id);
            List<Map<String,String>> expectedResult_3 = new List<Map<String,String>>();
            
            Map<String,String> option1 = new Map<String,String>{'label' => 'Azurceramique',  'value' => OrganizationCommons.ORG_AZURCERAMIQUE};
            expectedResult_3.add(option1);
            
            System.assertEquals(expectedResult_3, actualResult_3);
        }
        
    }
    
    /*@isTest
    public static void test_getTableInfo(){
        // Test 1: Account sin sap Id
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        SAPWS_Utility.SapResponse actualResponse_1 = Ficha360Controller.getTableInfo(acc.Id, OrganizationCommons.ORG_LORCERAM);
        
        System.assert( !actualResponse_1.success );
        System.assertEquals( actualResponse_1.message, 'Account must have a sap Id' );
        
        // Test 2: Account con sap Id pero sin sales Org
        Account acc2 = [SELECT Id FROM Account WHERE LastName = 'TestAcctCustomer1'];
        SAPWS_Utility.SapResponse actualResponse_2 = Ficha360Controller.getTableInfo(acc2.Id, '');
        
        System.assert( !actualResponse_2.success );
        System.assertEquals( actualResponse_2.message, 'Select a Sales Org' );
        
        // Test 3: Account con sap Id y sales Org
        SAPWS_Utility.SapResponse actualResponse_3;
        Test.setMock(HttpCalloutMock.class, new Ficha360MockHttpResponseGenerator());
        Test.startTest();
        	 actualResponse_3 = Ficha360Controller.getTableInfo(acc2.Id, OrganizationCommons.ORG_LORCERAM);
        Test.stopTest();
        
        System.assert( actualResponse_3.success );
        String jsonResponse = '"{\"balance_to_pay\":0,\"balance_to_refund\":0}"';
        System.assertEquals( actualResponse_3.json, jsonResponse );
    }*/
    
    @isTest
    public static void test_getTableInfo(){
        // Test 1: Account sin sap Id
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        SAPWS_Utility.SapResponse actualResponse_1 = (SAPWS_Utility.SapResponse) Ficha360Controller.getTableInfo(acc.Id, OrganizationCommons.ORG_LORCERAM);
        
        System.assert( !actualResponse_1.success );
        System.assertEquals( actualResponse_1.message, Label.Ficha360_Credit_Status_Unavaileble);
        
        // Test 2: Account con sap Id pero sin sales Org
        Account acc2 = [SELECT Id FROM Account WHERE LastName = 'TestAcctCustomer1'];
        SAPWS_Utility.SapResponse actualResponse_2 = (SAPWS_Utility.SapResponse) Ficha360Controller.getTableInfo(acc2.Id, '');
        
        System.assert( !actualResponse_2.success );
        System.assertEquals( actualResponse_2.message, 'Select a Sales Org' );
        
        // Test 3: Account con sap Id y sales Org
        SAPWS_Utility.SapResponse actualResponse_3;
        HttpResponse res = new HttpResponse();
        res.setHeader('x-csrf-token', 'token churro');
        res.setHeader('Set-Cookie', 'cookie churrito');
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        
        HttpResponse res2 = new HttpResponse();
        res2.setStatusCode(200);
        String jsonResponse = '"{\"balance_to_pay\":0,\"balance_to_refund\":0}"';
        res2.setBody(jsonResponse);
        
        Continuation firstContinuationResponse;
        SAPWS_Utility.SapResponse secondContinuationResponse;
        List<String> labels1 = new List<String>{'Continuation-1'};
        List<String> labels2 = new List<String>{'Continuation-3'};
        Ficha360Controller ficha360Instance = new Ficha360Controller();
        
        Test.setContinuationResponse(labels1[0], res);
        Test.setContinuationResponse(labels2[0], res2);
        
        	Continuation firstContinuation = (Continuation) Ficha360Controller.getTableInfo(acc2.Id, OrganizationCommons.ORG_LORCERAM);
        	Ficha360Controller.checkValidToken(labels1, (Object) new List<String>{acc2.Id, OrganizationCommons.ORG_LORCERAM});
        
        	System.debug('First Continuation request: ' + firstContinuation.getRequests());
        	System.assert(firstContinuation.getRequests().get(labels1[0]).getEndpoint().contains('ping'));
        	firstContinuationResponse = (Continuation) Test.invokeContinuationMethod(ficha360Instance, firstContinuation);
        	
        	System.debug('firstContinuationResponse: ' + firstContinuationResponse);
        	System.debug('First Continuation request: ' + firstContinuationResponse.getRequests() );
        	System.assert(firstContinuationResponse.getRequests().get(labels2[0]).getEndpoint().contains('zcli'));
        
        	Ficha360Controller.returnTableInfo(labels2, null);
        	secondContinuationResponse = (SAPWS_Utility.SapResponse) Test.invokeContinuationMethod(ficha360Instance, firstContinuationResponse);
        	System.debug('secondContinuationResponse: ' + secondContinuationResponse);
        Test.startTest();	
        Test.stopTest();
        
        System.assert(secondContinuationResponse.success);
        System.assert(secondContinuationResponse.json.contains('balance_to_pay'));
    }
}