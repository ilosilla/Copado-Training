@isTest public class OAttachmentsServiceTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
    }
    
    @isTest public static void testAttachments() {
        Opportunity opp = [select Id from Opportunity limit 1];
        OAttachmentDTO dto = new OAttachmentDTO();
        dto.fileName = 'text.txt';
        dto.parentId = opp.Id;
        dto.content = 'This is the file content';
        OAttachmentsService.createAttachments(new List<OAttachmentDTO>{dto});
        ContentVersion[] versions = OAttachmentsService.getSObjectAttachments(opp.Id);
        System.assertEquals(1, versions.size(), '1 file expected');
    }

}