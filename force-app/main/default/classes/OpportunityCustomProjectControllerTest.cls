@isTest public with sharing class OpportunityCustomProjectControllerTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
    }

    @isTest private static void readCustomProjectData_1()  {
        Opportunity opp = [select id from Opportunity limit 1];
        OpportunityCustomProjectController.ProjectDTO dto = OpportunityCustomProjectController.readCustomProjectData(opp.Id, null);
        System.assertNotEquals(null, dto, 'No result returned');
    }

    @isTest private static void saveCustomProject() {
        Opportunity opp = [select id from Opportunity limit 1];
        OppCustomProject__c cp = new OppCustomProject__c();
        cp.Opportunity__c = opp.Id;
        cp.ProjectType__c = 'KRION';
        cp.ProductManager__c = UserInfo.getUserId();
        cp.DeliveryDate__c = System.today();
        
        // test saveCustomProject
        OpportunityCustomProjectController.ResultDTO dto = OpportunityCustomProjectController.saveCustomProject(cp);
        System.assertEquals(true, dto.success);
        cp.Id = dto.arg;
        
        // readCustomProjectData
        OpportunityCustomProjectController.ProjectDTO dto2 = OpportunityCustomProjectController.readCustomProjectData(opp.Id, dto.arg);
        System.assertNotEquals(null, dto2, 'No result returned');

        // test saveRequestLines
        OppCustomProjectRequest__c[] reqs = new List<OppCustomProjectRequest__c>();
        reqs.add(new OppCustomProjectRequest__c(ProductDescription__c = 'Other'));
        reqs.add(new OppCustomProjectRequest__c(ProductDescription__c = 'Other'));        

        OpportunityCustomProjectController.saveRequestLines(cp.Id, reqs, new List<OppCustomProjectRequest__c>());
        OppCustomProjectRequest__c[] result1 = [select Id, OppCustomProject__c from OppCustomProjectRequest__c where OppCustomProject__c = :cp.Id];
        System.assertEquals(2, result1.size());

        OppCustomProjectRequest__c[] listI = new List<OppCustomProjectRequest__c>();
        listI.add(result1[0]);

        OppCustomProjectRequest__c[] listD = new List<OppCustomProjectRequest__c>();
        listD.add(result1[1]);

        OpportunityCustomProjectController.saveRequestLines(cp.Id, listI, listD);

        OppCustomProjectRequest__c[] result2 = [select Id, OppCustomProject__c from OppCustomProjectRequest__c where OppCustomProject__c = :cp.Id];
        System.assertEquals(1, result2.size());

    }

}