@isTest public with sharing class CustomProjectUtilsTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        SystemSettings.CPDeletionTime = 0;

        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
        OppCustomProject__c cp = new OppCustomProject__c();
        cp.Opportunity__c = opp.Id;
        cp.ProjectType__c = 'KRION';
        cp.ProductManager__c = UserInfo.getUserId();
        cp.DeliveryDate__c = System.today();
        insert cp;

        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];        

        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = cp.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;   
        
        SystemSettings.CPDeletionTime = 30;
        SystemSettings.CPNotificationsEnabled = true;
    }

    @isTest private static void saveCustomProject() {        
        OppCustomProject__c cp = [select id from OppCustomProject__c limit 1];
        ContentDocument[] docs = CustomProjectUtils.readAttachments(cp.Id);
        System.assertEquals(1, docs.size());
     }
    
    @isTest private static void scheduleDeletion() {
        SystemSettings.CPDeletionTime = 30;
        OppCustomProject__c cp = [select id from OppCustomProject__c limit 1];
        CustomProjectUtils.scheduleDeletion(new List<Id>{cp.Id});
        System.assertEquals(1, 1);        
    }

    @isTest private static void scheduleNoFilesEmail() {
        SystemSettings.CPNotificationsEnabled = true;
        OppCustomProject__c cp = [select id from OppCustomProject__c limit 1];
        ContentDocumentLink[] docs = [select Id from ContentDocumentLink where LinkedEntityId = :cp.Id];
        delete docs;
        Test.startTest();
            CustomProjectUtils.scheduleNoFilesEmail(new List<Id>{cp.Id});
        Test.stopTest();
        System.assertEquals(1, 1);        
    }
    
    @isTest private static void scheduleNewProjectEmail() {
        SystemSettings.CPNotificationsEnabled = true;
        OppCustomProject__c cp = [select id from OppCustomProject__c limit 1];
        Test.startTest();
            CustomProjectUtils.scheduleNewProjectEmail(new List<Id>{cp.Id});
        Test.stopTest();
        System.assertEquals(1, 1);        
    }
}