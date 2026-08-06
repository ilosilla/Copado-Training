@isTest public class SAPProxyTest {
    
    @isTest static void testConnect() {

        String theJSON = '{"key":"value"}';
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new SAPProxyTest.SAPProxyMockTest());
        
        // Instantiate the class to test
        SAPProxy instance = new SAPProxy(SAPProxy.HELLO_SERVICE);
        instance.resourceId = '123456';
        instance.queryString = 'param=1';
        instance.inputJSON = theJSON;
        
        // Call the method to test
        Test.startTest();
        Boolean success = instance.connectToSAP();
        Test.stopTest();

        // Perform assertions 
        System.assertEquals(true, success, 'Http request should have been succesful');
        System.assertEquals(200, instance.statusCode, '200 expected');
        System.assertEquals(theJSON, instance.receivedJSON, 'Received JSON not what expecrted');
    }

    @isTest static void testConnectError() {

        String theJSON = '{"key":"value"}';

        // Set up mock HTTP callout
        SAPProxyTest.SAPProxyMockTest mocker = new SAPProxyTest.SAPProxyMockTest();
        mocker.testError = true;

        Test.setMock(HttpCalloutMock.class, mocker);        
        // Instantiate the class to test
        SAPProxy instance = new SAPProxy(SAPProxy.HELLO_SERVICE);
        instance.resourceId = '123456';
        instance.queryString = 'param=1';
        instance.inputJSON = theJSON;
        
        // Call the method to test
        Test.startTest();
        Boolean success = instance.connectToSAP();
        Test.stopTest();

        // Perform assertions 
        System.assertEquals(false, success, 'false expected');
        System.assertNotEquals(200, instance.statusCode, 'Error status expected');

        List<SAPProxy.SAPResponse> results = instance.getResponse();
        System.assertNotEquals(0, results.size(), 'There should be at least one item in the results list');
    }


    public class SAPProxyMockTest implements HttpCalloutMock {
        
        public Boolean testError = false;

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response            
            String js = request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setHeader('x-csrf-token', 'toctoctoc');
            mockResponse.setHeader('set-cookie', 'cooookie');
            if (this.testError) {
                String errorJson = '[{"ERROR":{"ID":"016","TYPE":"E","MESSAGE":"&Referred invoice is from another customer&."},"INDEX":1,"SUCCESS":false},{"ERROR":{"ID":"030","TYPE":"E","MESSAGE":"Missing sales organisation or distribution channel"},"INDEX":1,"SUCCESS":false}]';
                mockResponse.setStatusCode(400);
                mockResponse.setBody(errorJson);
            } else {
                mockResponse.setStatusCode(200);
                mockResponse.setBody(js);
            }
            return mockResponse;
        }
    }
    
}