@isTest public class OppFacadeMailerTest {

    @testSetup private static void testSetup() {
        DataFactoryOppFacade.createFacade();
    }

    @isTest private static void testSendNewFacadeMail() {
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        OppFacadeMailer mailer = new OppFacadeMailer(f.Id);
        Test.startTest();
        mailer.sendNewFacadeMail();
        Integer nsent = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertNotEquals(0, nsent, 'An email should have been sent');
    }

    @isTest private static void testSendDeletedFacadeMail() {        
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        OppFacadeMailer mailer = new OppFacadeMailer(f.Id);
        Test.startTest();
        mailer.sendDeletedFacadeMail();
        Integer nsent = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertNotEquals(0, nsent, 'An email should have been sent');
    }

    @isTest private static void testSendAttachmentsEmail_1() {
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        OppFacadeMailer mailer = new OppFacadeMailer(f.Id);
        Test.startTest();
        mailer.sendAttachmentsEmail();
        Integer nsent = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(0, nsent, 'An email should not have been sent (there is an attachment)');
    }

    @isTest private static void testSendAttachmentsEmail_2() {
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        ContentDocumentLink[] lnk = [select Id from ContentDocumentLink where LinkedEntityId = :f.id ];
        delete lnk;
        OppFacadeMailer mailer = new OppFacadeMailer(f.Id);
        Test.startTest();
        mailer.sendAttachmentsEmail();
        Integer nsent = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertNotEquals(0, nsent, 'An email should  have been sent');
    }
       
    @isTest private static void testSendDrawingsMail() {
        Integer nsent = 0;
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        List<ContentVersion> versions = [SELECT Id FROM ContentVersion];
        if (versions.size() > 0) {
            List<String>ids = new List<String>{versions[0].Id};
            OppFacadeMailer mailer = new OppFacadeMailer(f.Id);
            Test.startTest();
                mailer.sendDrawingsMail(ids);
                nsent = Limits.getEmailInvocations();
            Test.stopTest();
        }
        System.assertNotEquals(0, nsent, 'An email should  have been sent');
    }

} // class