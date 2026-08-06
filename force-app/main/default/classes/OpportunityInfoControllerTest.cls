@isTest
public class OpportunityInfoControllerTest {
    @testSetup
    private static void testSetup() {
        testUtils.enableTriggers();
    }

    @isTest
    private static void testKitchenData() {
        String contextLabel = [Select Execution_Context__c From User Where  Id = :UserInfo.getUserId()].Execution_Context__c;
        Execution_Context__mdt context = [Select MasterLabel, DeveloperName,OwnerAssignation__c, Has_SAP__c, ExtendedOpps__c, PriceRequest__c From Execution_Context__mdt Where DeveloperName = :contextLabel];
        context.ExtendedOpps__c = 'CUSTOMP,KITCHEN,FACADE';

        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];

        // Kitchen
        OppKitchen__c k = new OppKitchen__c();
        k.Opportunity__c = opp.Id;
        k.ProductType__c = TestUtils.getPicklistOption(OppKitchen__c.ProductType__c);
        k.ProductQuoted__c = 'PQ';
        k.ProductLine2__c = 'Emotion';
        k.PricingCondition__c = TestUtils.getPicklistOption(OppKitchen__c.PricingCondition__c);
        insert k;
        
        OpportunityInfoController.InfoDTO aux = OpportunityInfoController.readOpportunityInfo(opp.Id);
        Assert.areEqual(true, aux.isKitchen, 'No tiene un Opportunity Kitchen');

        OpportunityInfoController.deleteKitchen(aux.kitchenId);
        aux = OpportunityInfoController.readOpportunityInfo(opp.Id);
        Assert.areEqual(false, aux.isKitchen, 'No debe de tener una Opportunity Kitchen');
    }

    @isTest
    private static void testCustomProjectData() {
        SystemSettings.CPDeletionTime = 10;

        String contextLabel = [Select Execution_Context__c From User Where  Id = :UserInfo.getUserId()].Execution_Context__c;
        Execution_Context__mdt context = [Select MasterLabel, DeveloperName,OwnerAssignation__c, Has_SAP__c, ExtendedOpps__c, PriceRequest__c From Execution_Context__mdt Where DeveloperName = :contextLabel];
        context.ExtendedOpps__c = 'CUSTOMP,KITCHEN,FACADE';

        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];

        // Kitchen
        OppCustomProject__c cp = new OppCustomProject__c();
        cp.Opportunity__c = opp.Id;
        cp.ProjectType__c = 'KRION';
        cp.ProductManager__c = UserInfo.getUserId();
        cp.DeliveryDate__c = System.today();
        Test.startTest();
        insert cp;
        OpportunityInfoController.InfoDTO aux = OpportunityInfoController.readOpportunityInfo(opp.Id);
        Assert.areEqual(true, aux.isCustomProject, 'No tiene un Opportunity Custom Project');
        Test.stopTest();
        
        //OpportunityInfoController.InfoDTO aux = OpportunityInfoController.readOpportunityInfo(opp.Id);
        //Assert.areEqual(false, aux.isCustomProject, 'Tiene un Opportunity Custom Project');

        OpportunityInfoController.deleteCustomProject(aux.customProjectId);
        aux = OpportunityInfoController.readOpportunityInfo(opp.Id);
        Assert.areEqual(false, aux.isKitchen, 'No debe de tener una Opportunity Custom Project');
    }
}