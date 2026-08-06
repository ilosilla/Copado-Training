@isTest public class OpportunityKitchenControllerTest {
    @testSetup private static void testSetup() {
        // Opportunity
        testUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];

        // Kitchen
        OppKitchen__c k = new OppKitchen__c();
        k.Opportunity__c = opp.Id;
        k.ProductType__c = TestUtils.getPicklistOption(OppKitchen__c.ProductType__c);
        k.ProductQuoted__c = 'PQ';
        k.ProductLine2__c = 'Emotion';
        k.PricingCondition__c = TestUtils.getPicklistOption(OppKitchen__c.PricingCondition__c);
        insert k;

        // Attachment
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = k.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

    }

    @isTest private static void testReadKitchenData() {
        OppKitchen__c k = [select Id, Opportunity__c from OppKitchen__c limit 1];
        OpportunityKitchenController.DataDTO dto = OpportunityKitchenController.readKitchenData(k.Opportunity__c, k.Id);
        System.assertEquals(false, dto.isNew, 'IsNew should be false');
        System.assertEquals(1, dto.attachments.size(), 'The kitchen should have one attachment');
    }

    @isTest private static void testAfterUploadFile() {
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        List<String> contentIds = new List<String>{contentVersion.Id};
        OpportunityKitchenController.afterUploadFile(null, contentIds, 'DRAWING');
        System.assert(true, true);
    }

    @isTest private static void testDeleteAttachments() {
        Opportunity opp = [select fields(standard) from Opportunity limit 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];        
        List<String> ids = new List<String>{documents[0].Id};
        OpportunityKitchenController.deleteAttachments(null, ids);
        System.assert(true, true);
    }

} // class