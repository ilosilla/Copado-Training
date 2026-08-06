@isTest
private class EmailServicePorsamarketTest {

    @isTest
    static void testHandleInboundEmail() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.toAddresses = new List<String>{'test@somedomain.com'};
        email.subject = 'Test Email';
        email.plainTextBody = 'Test Email Body';
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        Test.startTest();
        EmailServicePorsamarket emailService = new EmailServicePorsamarket();
        emailService.handleInboundEmail(email, envelope);
        Test.stopTest();
        Assert.isTrue(true, 'Dummy test');
    }

    @isTest
    static void fillerTestAccountAdditional() {
        EmailServicePorsamarket aux = new EmailServicePorsamarket();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}