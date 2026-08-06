@isTest public with sharing class CustomProjectMailerTest {

    @testSetup private static void testSetup() {
        testUtils.enableTriggers();
        SystemSettings.CPDeletionTime = 0;
        Opportunity opp = DataFactoryOpportunity.createTradeOpportunities(1, 1)[0];
        OppCustomProject__c cp = new OppCustomProject__c();
        cp.Opportunity__c = opp.Id;
        cp.ProjectType__c = 'KRION';
        cp.ProductManager__c = UserInfo.getUserId();
        cp.DeliveryDate__c = System.today();
        Database.insert(cp);
    }

    @isTest private static void testMails() {
        Boolean isOK = false;
        try {
            OppCustomProject__c cp = [select Id from OppCustomProject__c limit 1];
            CustomProjectMailer agent = new CustomProjectMailer();
            agent.sendStageChangeMail(cp.Id, 'QUALIFICATION' );
            agent.sendmaterialMail(cp.Id);
            agent.sendNewProjectMail(cp.Id);
            agent.sendAttachmentsMail(cp.Id);
            agent.sendDrawingsMail(cp.Id);
            agent.sendQuoteMail(cp.Id);
            agent.sendDeletionMail(cp.Id);
            isOk = true;
        } catch (Exception e) {
            isOK = false;
        }
        System.assertEquals(true, isOk);
    }

}