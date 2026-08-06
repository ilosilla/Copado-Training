@isTest public with sharing class CustomProjectAgentTest {

    @testSetup private static void testSetup() {
        testUtils.enableTriggers();
        SystemSettings.CPDeletionTime = 0;
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
        OppCustomProject__c cp = new OppCustomProject__c();
        cp.Opportunity__c = opp.Id;
        cp.ProjectType__c = 'KRION';
        cp.ProductManager__c = UserInfo.getUserId();
        cp.DeliveryDate__c = System.today();
        insert cp;
    }

    @isTest private static void testDeleteProject_1() {        
        OppCustomProject__c cp = [select Id from OppCustomProject__c limit 1];
        CustomProjectAgent agent = new CustomProjectAgent();
        agent.setAction('DELETE');
        agent.setProjectIds(new List<Id>{cp.Id});
        agent.executeAction();
        OppCustomProject__c[] cp2 = [select Id from OppCustomProject__c];
        System.assertEquals(0, cp2.size(), 'Project has no attachments and should have been deleted!');
    }

    @isTest private static void testDeleteProject_2() {
        OppCustomProject__c cp = [select Id from OppCustomProject__c limit 1];
        AttachmentUtilsTest.attachTestFile(cp.Id, 'test1.txt');
        CustomProjectAgent agent = new CustomProjectAgent();
        agent.setAction('DELETE');
        agent.setProjectIds(new List<Id>{cp.Id});
        agent.executeAction();
        OppCustomProject__c[] cp2 = [select Id from OppCustomProject__c];
        System.assertEquals(1, cp2.size(), 'Project has attachments and should have not been deleted!');
    }

}