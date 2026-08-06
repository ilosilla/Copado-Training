@isTest public with sharing class SAPCPIProxyTest {

    @testSetup public static void testSetup() {

        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    @isTest private static void testSAPCPI() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());
        String error = null;
        SAPCPIProxy proxy = new SAPCPIProxy('/dummy');
        proxy.setJSONBody('{"dummy":"test"}');
        proxy.setMethod('POST');
        proxy.setPath('/path');
        proxy.setQueryString('test=true');
        Test.startTest();
        try {
            proxy.callCPI();
        } catch(HttpException ex) {
            error = ex.getMessage();
        }
        Test.stopTest();        
        Integer code = proxy.getResponseCode();
        String body = proxy.getResponseBody();
        Assert.isNull(error, 'No error expected');
        Assert.areEqual(200, code, '200 expected');
        Assert.isNotNull(body,'A body is expected');
        Assert.isTrue(proxy.isSuccess(), 'True expected');
    }

    public class Mocker implements HttpCalloutMock {
        
        public Boolean testError = false;
        public String customResponse = null;

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response     
            String dummyResponse = '';       
            request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            if (this.testError) {
                mockResponse.setStatusCode(400);
                dummyResponse = 'Generic Error';
            } else {
                mockResponse.setStatusCode(200);
                dummyResponse = 'OK';
            }
            if (String.isNotBlank(this.customResponse )) {
                mockResponse.setBody(this.customResponse);
            } else {
                mockResponse.setBody(dummyResponse);
            }
            return mockResponse;
        }
    }

}