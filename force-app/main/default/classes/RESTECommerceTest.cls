@isTest public with sharing class RESTECommerceTest {

    @testSetup static void testSetup() {
        TestUtils.enableTriggers();
    }

    @isTest public static  void ping() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/ecommerce/samples';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTECommerce.ping();
        System.assertEquals(200, response.statusCode);
        Test.stopTest();
    }

    @isTest public static  void post() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        Order order = new Order();
        order.AccountId = DataFactoryAccount.createPersonAccounts(1)[0].Id;
        order.Status = 'Draft';
        order.Sap_Id__c = '0011111111';
        order.EffectiveDate = System.today();        
        String JsonMsg = JSON.serialize(order);
        request.requestUri = '/services/apexrest/ecommerce/samples';       
        request.requestBody = Blob.valueOf(JsonMsg);
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTECommerce.create(order);
        System.assertEquals(201, response.statusCode);
        Test.stopTest();
    }

} // class