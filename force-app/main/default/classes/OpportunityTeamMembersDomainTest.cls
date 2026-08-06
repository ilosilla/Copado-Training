@isTest
public class OpportunityTeamMembersDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        DataFactoryOpportunity.createRetailOpportunities(2,2);
    }

    @isTest
    static void addTeamMembers() {
        Opportunity opp = [SELECT Id, AccountId,  Last_Activity_Date__c from Opportunity limit 1];
        Account acc = [SELECT Id, Last_Activity_Date__c from Account where Id =: opp.AccountId];
        opp.Last_Activity_Date__c = opp.Last_Activity_Date__c.addDays(-8);
        acc.Last_Activity_Date__c = acc.Last_Activity_Date__c.addDays(-8);
        update opp;
        update acc;
        
        DateTime beforeOpp = opp.Last_Activity_Date__c;
        DateTime beforeAcc = acc.Last_Activity_Date__c;
        User usr = [SELECT Id from User where Id <> : UserInfo.getUserId() and isActive = true and ProfileId =: UserInfo.getProfileId() limit 1];
        
        Test.startTest();
        OpportunityTeamMember teamMember = new OpportunityTeamMember(UserId = usr.Id, OpportunityId = opp.Id);
        insert teamMember;
        Test.stopTest();

        new OpportunityTeamMembersDomain(new List<OpportunityTeamMember>{teamMember});
        
        opp = [SELECT Id, AccountId,  Last_Activity_Date__c from Opportunity where Id =: opp.Id];
        acc = [SELECT Id, Last_Activity_Date__c from Account where Id =: acc.Id];
        System.assert(acc.Last_Activity_Date__c != beforeAcc, 'No se ha actualizado el Last Activity del Account');
        System.assert(opp.Last_Activity_Date__c != beforeOpp, 'No se ha actualizado el Last Activity del Opportunity');
        System.assert(opp.Last_Activity_Date__c.date() == acc.Last_Activity_Date__c.date(), 'Account y Opp no tienen la misma fecha');
    }
}