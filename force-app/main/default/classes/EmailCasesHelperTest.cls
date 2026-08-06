@isTest
private class EmailCasesHelperTest {

    @testSetup static void testSetup() {
        DataFactoryCase.createClaims(2);
    }
    
    @isTest
    static void testAssignCasesToMessages() {        
        Case[] cases = [select CaseNumber from Case];
        Assert.isTrue(cases.size() >= 2, '2 cases needed');

        EmailMessage[] messages = new List<EmailMessage>();

        EmailMessage m0 = new EmailMessage();
        m0.ToAddress = 'faeke@fdmn.cxm';
        m0.Subject= 'Case '+ cases[0].CaseNumber + ': Subject';
        messages.add(m0);

        EmailMessage m1 = new EmailMessage();
        m1.ToAddress = 'faeke@fdmn.cxm';
        m1.Subject= 'Case '+ cases[1].CaseNumber + ': Subject';
        messages.add(m1);

        EmailMessage m2 = new EmailMessage();
        m2.ToAddress = 'faeke@fdmn.cxm';
        m2.Subject= 'Case 999999: Subject';
        messages.add(m2);

        EmailCasesHelper.assignCasesToMessages(messages);

        Assert.isNotNull(messages[0].ParentId, 'A case should have been found for the first message');
        Assert.isNotNull(messages[1].ParentId, 'A case should have been found for the secod message');
        Assert.isNull(messages[2].ParentId, 'A case should NOT have been found for the third message');

    }

    @isTest static void testIncomingMail() {
        Case[] cases = [select CaseNumber from Case];
        Assert.isTrue(cases.size() >= 1, '1 cases needed');

        Messaging.InboundEmail inbound = new Messaging.InboundEmail();
        inbound.fromAddress = 'fromfake@fakedomain2.cxm';
        inbound.toAddresses = new List<String>{'tofake@fakedomain.cxm'};
        inbound.subject =  'Case '+ cases[0].CaseNumber + ': Subject';
        inbound.plainTextBody = 'This is the body';
        inbound.inReplyTo = 'xxx';

        EmailMessage m = EmailCasesHelper.createIncomingEmailMessage(inbound);
        Assert.isNotNull(m, 'A message should have been returned');    
    }


}