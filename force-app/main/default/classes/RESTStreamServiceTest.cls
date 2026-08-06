@isTest public with sharing class RESTStreamServiceTest {

    @isTest public static  void ping() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/stream';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTStreamService.get();
        System.assertEquals(200, response.statusCode);
        Test.stopTest();
    }
    
    @isTest public static  void post_OK() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');

        RESTStreamService.StreamDTO stream = new RESTStreamService.StreamDTO();
        stream.fileName = 'MGT_DailyLeads_1_test.xml';
        stream.agent = 'MaterialBankParser';
        stream.content = '<root><row><CONSIGNEE>7936</CONSIGNEE><CREATEDATE>07-14-2021 03:04:18</CREATEDATE>'
            + '<row><ORDERED1NAME>Sydney Kaufman</ORDERED1NAME><SHIPPED1NAME>Whitney Liang</SHIPPED1NAME><EntityId>37936</EntityId>'
            + '<CONTACT1EMAIL>skaufman@porcelanosa-usa.com</CONTACT1EMAIL><SHIPPED1EMAIL>Whitney_Liang@gensler.com</SHIPPED1EMAIL>'
            + '<CONTACT1PHONE>6467511180</CONTACT1PHONE><STREET1>75 Varick St 2nd Floor</STREET1><Company>One Hudson Square</Company>'
            + '<City>New York</City><State>New York</State><Zip>10013-1947</Zip><CompanyPractice>Manufacturer/Distributor</CompanyPractice>'
            + '<Title>Sales Coordinator</Title><row><ORDERID>0007030910904</ORDERID><TRACKINGNO>525213635449</TRACKINGNO>'
            + '<row><ProjectName>Jackie Robinson</ProjectName><QTYORIGINAL>2.0000</QTYORIGINAL><SKU>100287934</SKU><Name>Oxford Natural</Name>'
            + '<MBShipped>Y</MBShipped><MBSKU>100042672</MBSKU><SerialSKU/><Color>Natural</Color><ProjectType>Workplace</ProjectType>'
            + '<ProjectPhase>Concept Design</ProjectPhase><ProjectDescription>PreBuilt fit out on Spring Street samples</ProjectDescription>'
            + '</row></row><MOBILEPHONE/><CONTACTPREFERENCE>Any</CONTACTPREFERENCE><RELATEDPRODUCTS/></row></row></root>';

        String JsonMsg = JSON.serialize(stream);
        request.requestUri = '/services/apexrest/stream';       
        request.requestBody = Blob.valueOf(JsonMsg);
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTStreamService.post(stream);
        Test.stopTest();
        System.assertEquals(200, response.statusCode);
    }

    @isTest public static  void post_ERROR() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');

        RESTStreamService.StreamDTO stream = new RESTStreamService.StreamDTO();
        stream.fileName = 'MGT_DailyLeads_1_test.xml';
        stream.agent = 'MaterialBankParserXXX';
        stream.content = '<root><row><CONSIGNEE>7936</CONSIGNEE><CREATEDATE>07-14-2021 03:04:18</CREATEDATE>'
            + '<row><ORDERED1NAME>Sydney Kaufman</ORDERED1NAME><SHIPPED1NAME>Whitney Liang</SHIPPED1NAME><EntityId>37936</EntityId>'
            + '<CONTACT1EMAIL>skaufman@porcelanosa-usa.com</CONTACT1EMAIL><SHIPPED1EMAIL>Whitney_Liang@gensler.com</SHIPPED1EMAIL>'
            + '<CONTACT1PHONE>6467511180</CONTACT1PHONE><STREET1>75 Varick St 2nd Floor</STREET1><Company>One Hudson Square</Company>'
            + '<City>New York</City><State>New York</State><Zip>10013-1947</Zip><CompanyPractice>Manufacturer/Distributor</CompanyPractice>'
            + '<Title>Sales Coordinator</Title><row><ORDERID>0007030910904</ORDERID><TRACKINGNO>525213635449</TRACKINGNO>'
            + '<row><ProjectName>Jackie Robinson</ProjectName><QTYORIGINAL>2.0000</QTYORIGINAL><SKU>100287934</SKU><Name>Oxford Natural</Name>'
            + '<MBShipped>Y</MBShipped><MBSKU>100042672</MBSKU><SerialSKU/><Color>Natural</Color><ProjectType>Workplace</ProjectType>'
            + '<ProjectPhase>Concept Design</ProjectPhase><ProjectDescription>PreBuilt fit out on Spring Street samples</ProjectDescription>'
            + '</row></row><MOBILEPHONE/><CONTACTPREFERENCE>Any</CONTACTPREFERENCE><RELATEDPRODUCTS/></row></row></root>';

        String JsonMsg = JSON.serialize(stream);
        request.requestUri = '/services/apexrest/stream';       
        request.requestBody = Blob.valueOf(JsonMsg);
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTStreamService.post(stream);
        Test.stopTest();
        System.assertEquals(400, response.statusCode);

    }
    

}