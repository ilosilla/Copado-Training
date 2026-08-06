@isTest public with sharing class RESTTestServiceTest {

    @isTest private static void test001() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/openApi/v1/test-service/id?param=value'; 
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTTestService.get();
        Test.stopTest();
        System.assertEquals(200, response.statusCode);
     }

     @isTest private static void test002() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        request.requestBody = Blob.valueOf('Hola');
        request.requestUri = '/services/apexrest/openApi/v1/test-service/id?param=value'; 
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTTestService.post();
        Test.stopTest();
        System.assertEquals(200, response.statusCode);
     }
    }