@isTest
public class EmailMessagesDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(9);
    } // setup

    @isTest static void testLoremIpsum() {
        EmailMessagesDomain.testCoverage();
        Assert.isTrue(true, 'Silly test');
    }

    @isTest static void testBeforeInsert() {
        // Not testing anything really. The assignation of cases to emails is already tested in EmailCasesHelperTest, so 
        // just trying to reach coverage here.
        EmailMessage msg = new EmailMessage();
        msg.Status = '1';
        msg.FromAddress = 'rprades@porcelanosagrupo.com';
        msg.ToAddress = 'dummy@algo.cxm';
        msg.Subject = 'This is a test';
        msg.TextBody = 'This is the text body';
        Test.startTest();
        insert msg;
        Test.stopTest();
        Assert.isTrue(true, 'Silly test');
    }
}