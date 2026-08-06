@isTest public with sharing class CaseEmailSummarizerTest {
    @testSetup public static void testSetup() {
        AIPrompt__c p = new AIPrompt__c();
        p.Name = 'Test';
        p.DeveloperName__c = 'CLAIM-FACTORY-SUMMARY';
        p.SystemRole__c = 'Summarize these emails';
        p.UserRole__c =  'These are the emails: {0}';
        insert p;

        AIServiceTest.testSetup();
        Case[] cases = DataFactoryCase.createClaims(1);

        EmailMessage m = new EmailMessage();
        m.FromAddress = 'dummy@dummydomain.dum';
        m.FromName = 'Dummy Name';
        m.ToAddress = 'dummy_rec@dummydomain.dum';
        m.Subject = 'Dummy email';
        m.HtmlBody = '<h1>Test</h1>' + CaseEmailSummarizer.CLAIM_FACTORY_FORM_ID;
        m.TextBody = 'Test.' + CaseEmailSummarizer.CLAIM_FACTORY_FORM_ID;
        m.parentId = cases[0].Id;
        insert m;

    }

    @isTest public static void testSummarizeClaimFactoryEmails() {
        Test.setMock(HttpCalloutMock.class, new AIServiceTest.Mocker());
        Case c = [select Id from Case limit 1];        

        Test.startTest();
        CaseEmailSummarizer summarizer = new CaseEmailSummarizer();
        String summary = summarizer.summarizeClaimFactoryEmails(c.Id);
        Test.stopTest();

        Assert.isNotNull(summary);
    }

    @isTest public static void testSummarizeEmail() {
        Test.setMock(HttpCalloutMock.class, new AIServiceTest.Mocker());
        CaseEmailSummarizer summarizer = new CaseEmailSummarizer();
        Test.startTest();
        String s = summarizer.summarizeEmail('mailBody');
        Assert.isNotNull(s);
        Test.stopTest();
    }    
}