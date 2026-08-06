@isTest private class RESTOAttachmentsTest {
    
    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
    }    

    @isTest static void testPOST1() {
        Opportunity opp = [select Id from Opportunity limit 1];
        List<OAttachmentDTO> files = new List<OAttachmentDTO>();
        
        OAttachmentDTO dto1 = new OAttachmentDTO();
        dto1.fileName = 'f1.txt';
        dto1.parentId = opp.Id;
        dto1.content = 'Test 1';
        files.add(dto1);

        OAttachmentDTO dto2 = new OAttachmentDTO();
        dto2.fileName = 'f2.txt';
        dto2.parentId = opp.Id;
        dto2.content = 'Test 2';
        files.add(dto2);        

        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();

        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/oattachments';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTOAttachments.post(files);
        System.assertEquals(204, response.statusCode);
        Test.stopTest();
    }
    
}