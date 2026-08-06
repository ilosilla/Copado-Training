@isTest public class RESTCollectionsControllerTest {

    @testSetup static void testSetup() {
        TestUtils.enableTriggers();
        SAPCASesControllerTest.buildNewCase();  
    }

    @isTest private static void test001() {
        Case c = [select Id from Case limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/openApi/v1/collection/' + c.Id + '?approvedBy=' + UserInfo.getUserId(); 
        request.addParameter('approvedBy', UserInfo.getUserId());
        //Assert.areEqual('aaa', request.requestUri );      
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTCollectionsController.approve();
        Test.stopTest();
        System.assertEquals(204, response.statusCode);
        Case c2 = [select Id, Status from Case where Id = :c.Id limit 1];
        Assert.areEqual(CasesDomain.STATUS_APPROVED, c2.Status);
    }

    @isTest private static void test002() {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/openApi/v1/collection/22223333';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTCollectionsController.approve();
        Test.stopTest();
        Assert.areNotEqual(204, response.statusCode);        
    }
}