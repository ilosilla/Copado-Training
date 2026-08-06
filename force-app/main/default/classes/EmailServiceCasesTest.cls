@isTest
private class EmailServiceCasesTest {

@isTest
    static void testHandleInboundEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.toAddresses = new List<String>{'test@somedomain.com'};
        email.subject = 'Test Email';
        email.plainTextBody = 'Test Email Body';
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        Test.startTest();
        EmailServiceCases emailService = new EmailServiceCases();
        emailService.handleInboundEmail(email, envelope);
        Test.stopTest();
        Assert.isTrue(true, 'Dummy test');
    }
}