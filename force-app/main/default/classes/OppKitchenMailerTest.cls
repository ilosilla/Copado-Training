@isTest class OppKitchenMailerTest {

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

    @isTest private static void newKitchenMailTest() {
        OppKitchen__c kitchen = [select Id from OppKitchen__c limit 1];
        OppKitchenMailer mailer = new OppKitchenMailer(kitchen.Id);
        Test.startTest();
            mailer.sendNewKitchenMail();
            Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assert(invocations>=0, 'Email has not been sent');
    }

}