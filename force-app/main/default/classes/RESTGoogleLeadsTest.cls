/**
* @author 		Ramón Prades
* @date 		November 2022
* @group 		Leads
* @description  Test creating google ad leads
*/
@isTest public class RESTGoogleLeadsTest {

    private static String google_key = '111-222-3333';

    @testSetup public static void testSetup() {
        PorcelanosaSetting__c setting = new Porcelanosasetting__c();
        setting.key__c = 'GOOGLE_AD';
        setting.subkey__c = 'UK';
        setting.value1__c = RESTGoogleLeadsTest.google_key;
        setting.value2__c = UserInfo.getUserEmail();
        insert setting;

    }

    @isTest private static void testGetSubkey() {
       String uri =  'https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/uk' ;
       String result = RESTGoogleLeads.getSubKey(uri);
       System.assertEquals('UK', result, 'Expected subkey is uk');

       uri =  'https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/uk/' ;
       result = RESTGoogleLeads.getSubKey(uri);
       System.assertEquals('UK', result, 'Expected subkey is uk');

       uri =  'https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/uk?param=a&other=b' ;
       result = RESTGoogleLeads.getSubKey(uri);
       System.assertEquals('UK', result, 'Expected subkey is uk');
    }

    @isTest private static void testPOSTSettingOK() {
        PorcelanosaSetting__c setting = [select key__c, subkey__c, value1__c from PorcelanosaSetting__c limit 1];

        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        String jsonData = buildJSON();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/googleleads/' + setting.subkey__c.toLowerCase();        
        request.requestBody = Blob.valueof(jsonData);

        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
            RESTGoogleLeads.doPost();
        Test.stopTest();
        System.assertEquals(200, response.statusCode, 'no errors expected ' + response.responseBody.toString());       
        
        //Lead l = [select Id, LeadType__c from Lead limit 1];
        //System.assertEquals(LeadsService.GOOGLE_LEAD_TYPE, l.LeadType__c, 'Wrong lead type ' + l.LeadType__c);
    }

    @isTest private static void testGET() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/googleleads';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
            Boolean ok = false;
            RESTGoogleLeads.doGet();
            ok = true;
        Test.stopTest();
        System.assertEquals(200, response.statusCode, 'Status code returne should be 200');
    }

    
    @isTest private static void testPOSTJSONError() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        String jsonData = buildWrongJSON();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/googleleads';        
        request.requestBody = Blob.valueof(jsonData);

        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
            RESTGoogleLeads.doPost();
        Test.stopTest();
        System.assertEquals(400, response.statusCode, 'Wrong JSON expected (400)');        
    }

    @isTest private static void testPOSTSettingError() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        String jsonData = buildJSON();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/googleleads/nn';        
        request.requestBody = Blob.valueof(jsonData);

        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
            RESTGoogleLeads.doPost();
        Test.stopTest();
        System.assertEquals(400, response.statusCode, 'nn not found (400)');        
    }


    private static String buildJSON() {
        PorcelanosaSetting__c setting = [select key__c, subkey__c, value1__c from PorcelanosaSetting__c limit 1];
        RESTGoogleLeads.JSONLead jsonLead = new RESTGoogleLEads.JSONLead();
        jsonLead.google_key = setting.value1__C;
        jsonLead.adgroup_id = '999';
        jsonLead.api_version = '3';
        jsonLead.campaign_id = 'TEST_CAMPAIGN';
        jsonLead.is_test = false;
        jsonLead.lead_id = '1121212121';

        jsonLead.user_column_data = new List<UserLeadColumnData>();

        UserLeadColumnData d1 = new UserLeadColumnData(); 
        d1.column_id = 'FULL_NAME'; 
        d1.string_value = 'Martin Fowler';
        jsonLead.user_column_data.add(d1);

        UserLeadColumnData d2 = new UserLeadColumnData();
        d2.column_id = 'PHONE_NUMBER';
        d2.string_value = '123123123';
        jsonLead.user_column_data.add(d2);

        UserLeadColumnData d3 = new UserLeadColumnData();
        d3.column_id = 'EMAIL';
        d3.string_value = 'daddddd@somesite.cxm';
        jsonLead.user_column_data.add(d3);

        return JSON.serialize(jsonLead);
    }

    private static String buildWrongJSON() {
        return '{"lead_id": "lead_id1", "form_id": "form_id1", "google_key" : "' + RESTGoogleLeadsTest.google_key + '",'
            + '"user_column_data": [ '
            + '{"column_id" : "PHONE_NUMBER", "string_value": "25-25-25-25"},'
            + '{"column_id" : "EMAIL", "string_value": "hhh@somesite.cxm"},'
            + '{"column_id" : "FULL_NAME", "string_value": "Charles Barr"}'
            + ']}';
    }

} // class