@isTest public class RESTXEventTest {
    
    @testSetup static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryOpportunity.createRetailOpportunities(1, 1);
    }

    @isTest public static void ping() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/x-events';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTXEvent.ping();
        System.assertEquals(200, response.statusCode);
        Test.stopTest();
    }

    /**
     * Eventos soportados:
     * - QUOTE para indicar que se ha asociado un presupuesto a una oportunidad
     * {
     *   "event": "QUOTE",
     *   "source": "001003322",
    ¨*   "target": "0061x00000Ji6iPAAR",
     *   "args" : {
     *      "amount" : "5255.25",
     *      "currency": "GBP"
     *   }
     * }
     */
    @isTest public static  void post() {        
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        Opportunity opp = [select Id from Opportunity limit 1];
        String JSON = '{"event": "QUOTE","source": "001003322","target": "' + opp.Id + '","args" : {"amount" : "5000","currency": "GBP"}}';
        request.requestUri = '/services/apexrest/x-events';       
        request.requestBody = Blob.valueOf(JSON);
        RestContext.request = request; 
        RestContext.response= response;
        Map<String, String> args = new map<String, String>();
        args.put('amount', '5000');
        args.put('currency', 'GBP');

        Test.startTest();
        RESTXEvent.post('QUOTE', '001003322', opp.Id, args);
        System.assertEquals(204, response.statusCode); // Test OK
        Test.stopTest();

    }

    @isTest public static  void post2_error() {        
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        Opportunity opp = [select Id from Opportunity limit 1];
        String JSON = '{"event": "QUOTE","source": "001003322","target": "333","args" : {"amount" : "5000","currency": "GBP"}}';
        request.requestUri = '/services/apexrest/x-events';       
        request.requestBody = Blob.valueOf(JSON);
        RestContext.request = request; 
        RestContext.response= response;
        Map<String, String> args = new map<String, String>();
        args.put('amount', '5000');
        args.put('currency', 'GBP');

        Test.startTest();
        RESTXEvent.post('QUOTE', '001003322', '333', args);
        System.assertEquals(404, response.statusCode); // Test OK
        Test.stopTest();

    }    
}