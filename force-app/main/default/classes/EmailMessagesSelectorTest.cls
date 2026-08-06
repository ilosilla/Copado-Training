@isTest
public with sharing class EmailMessagesSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'ivan.losilla@porcelanosagrupo.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Email Subject');
        mail.setPlainTextBody('Email BODY');
        mail.setWhatId(accs[0].Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }

    @isTest
    private static void selectById() {
        Set<Id> emailMessagesIds = new Set<id>();
        for(EmailMessage l : [Select Id from EmailMessage]) {
            emailMessagesIds.add(l.id);
        }

        List<EmailMessage> result = new EmailMessagesSelector().selectById(emailMessagesIds);
        System.assertEquals(1, result.size(), '5 EmailMessages expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        EmailMessage ct = [Select Id from EmailMessage LIMIT 1];
        EmailMessage result = new EmailMessagesSelector().selectById(ct.Id);
        System.assert(result != null, 'No se ha encontrado el EmailMessage');
    }
}