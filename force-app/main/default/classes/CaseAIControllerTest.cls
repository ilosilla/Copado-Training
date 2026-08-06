@isTest
public class CaseAIControllerTest {

    @testSetup private static void testSetup() {
        CaseEmailSummarizerTest.testSetup();
    }


@IsTest
    public static void summarizeFactoryEmails() {
        Test.setMock(HttpCalloutMock.class, new AIServiceTest.Mocker());
        Case c = [select Id from Case limit 1];
        Test.startTest();
        String s = CaseAIController.summarizeFactoryEmails(c.Id);
        Test.stopTest();
        Assert.isNotNull(s);
    }

}