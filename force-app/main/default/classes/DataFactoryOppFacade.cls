/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Data factories
* @description 	Opp Facade
*/
public  class DataFactoryOppFacade {

    public static Boolean CreateAttachment = true;

    public static OppFacade__c createFacade() {
        if (!Test.isRunningTest()) {
            return null;
        }

        // Opportunity
        testUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
    
        // Facade
        OppFacade__c k = new OppFacade__c();
        k.Opportunity__c = opp.Id;
        k.Stage__c = TestUtils.getPicklistOption(OppFacade__c.Stage__c);
        k.DesignPhase__c = TestUtils.getPicklistOption(OppFacade__c.DesignPhase__c);
        k.Manager__c = UserInfo.getUserId();
        k.CostEstimateMethod__c = TestUtils.getPicklistOption(OppFacade__c.CostEstimateMethod__c);
        insert k;
    
        // Attachment
        if (DataFactoryOppFacade.CreateAttachment) {
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

        return k;
    } // createFacade
}