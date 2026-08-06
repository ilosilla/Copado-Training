@isTest
private class RESTOpenAPIV2HelperTest {

    @isTest static void testExtractUriParts() {
        RestRequest request = new RestRequest();
        request.requestURI = '/openapi/v2/debug/12345';
        request.params.put('status', 'successful');

        RESTOpenAPIV2Helper helper = new RESTOpenAPIV2Helper(request, 'GET');
        System.assertEquals('debug', helper.resourceName);
        System.assertEquals('12345', helper.resourceId);
    }

   @isTest  static void testClaimParams() {
        RestRequest request = new RestRequest();
        request.requestURI = '/openapi/v2/claim/12345';
        request.params.put('approved', '1231213');

        RESTOpenAPIV2Helper helper = new RESTOpenAPIV2Helper(request, 'GET');
        helper.processResource();
        Assert.areEqual(400, helper.statusCode, '400 expected' );
    }

    @isTest  static void testDebug() {
        RestRequest request = new RestRequest();
        request.requestURI = '/openapi/v2/debug/12345';
        request.params.put('approved', '1231213');

        RESTOpenAPIV2Helper helper = new RESTOpenAPIV2Helper(request, 'GET');
        helper.processResource();
        Assert.areEqual(200, helper.statusCode, '200 expected' );
    }


}