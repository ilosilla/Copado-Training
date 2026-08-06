@isTest class RESTWaitingListTest {

    @testSetup static void testSetup() {
        TestUtils.enableTriggers();

        DataFactoryOrganization.createData();
    }

    @isTest static void test1 () {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/waitinglist';
        RestContext.request = request; 
        RestContext.response= response;
        
        Test.startTest();
        RESTWaitingList.ping();
        RESTWaitingList.create('Test', 'LastName', '8768768768756', 'testemauil@sdfsd.es', '3031');
        Test.stopTest();

        WaitingList__c[] wlists  = [select Id from WaitingList__c];
        System.assertEquals(1, wlists.size(), 'Test1a: There should be one and only one waiting list');
    }
    
} // class