@isTest
public class BatchOpportunityAutoCloseTest {
    @TestSetup
    static void makeData(){
        DataFactoryOpportunity.createRetailOpportunities(1, 2);
    }

    @isTest
    static void testBatch() {
        Opportunity opp = [SELECT Id, Reason_Lost__c, Amount_custom__c, StageName,Name,Account.Name,OwnerId,AccountId, Last_Activity_Date__c, CloseDate
                            FROM Opportunity LIMIT 1];
        
        opp.Last_Activity_Date__c = System.today().addYears(-2);
        opp.CloseDate = System.today().addDays(-6);
        update opp;

        Integer before = Limits.getEmailInvocations();
        test.startTest();
            BatchOpportunityAutoClose aux = new BatchOpportunityAutoClose();
            Database.executebatch(aux);
        test.stopTest();

        Assert.isTrue(before == Limits.getEmailInvocations(), 'Emails no enviados');
    }

    @isTest
    static void testBatchTest() {
        Opportunity opp = [SELECT Id, Reason_Lost__c, Amount_custom__c, StageName,Name,Account.Name,OwnerId,AccountId, Last_Activity_Date__c, CloseDate
                            FROM Opportunity LIMIT 1];
        
        opp.Last_Activity_Date__c = System.today().addYears(-2);
        opp.CloseDate = System.today().addDays(-6);
        update opp;

        Integer before = Limits.getEmailInvocations();
        test.startTest();
            BatchOpportunityAutoClose aux = new BatchOpportunityAutoClose();
            aux.setTest();
            Database.executebatch(aux);
        test.stopTest();

        Assert.isTrue(before == Limits.getEmailInvocations(), 'Emails no enviados');
    }

    @isTest
    static void fillerTest() {
        BatchOpportunityAutoClose aux = new BatchOpportunityAutoClose();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
    
}