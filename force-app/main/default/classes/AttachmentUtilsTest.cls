/**
* @author 		Ramón Prades
* @date 		July 2021
* @group 		Test
* @description 	test class
*/
@isTest public class AttachmentUtilsTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
        attachTestFile(opp.Id, 'test.txt');
    }
    
    @isTest public static void getSObjectAttachments() {
        Opportunity opp = [select Id from Opportunity limit 1];
        ContentVersion[] versions = AttachmentUtils.getSObjectAttachments(opp.Id);
        System.assertEquals(1, versions.size(), '1 file expected');
    }

    @isTest public static void getSObjectAttachmentsMap() {
        Opportunity opp = [select Id from Opportunity limit 1];
        Map<String, ContentVersion> versions = AttachmentUtils.getSObjectAttachmentsMap(opp.Id);
        System.assertEquals(1, versions.size(), '1 file expected');
    }

    /*********************************************************/
    /******************** NON TEST METHODS ********************/
    /*********************************************************/

    public static void attachTestFile(Id objectId, String fileName) {
        ContentVersion cv = new ContentVersion(
            Title = fileName.substringBeforeLast('.'),
            PathOnClient = fileName,
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objectId;
        cdl.ContentDocumentId = docId;
        cdl.shareType = 'V';
        Insert cdl;        
    } // attachTestFile

}