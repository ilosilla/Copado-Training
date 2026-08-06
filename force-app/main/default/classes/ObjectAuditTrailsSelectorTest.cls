@SuppressWarnings('PMD.EmptyWhileStmt, PMD.EmptyStatementBlock')
@isTest public with sharing class ObjectAuditTrailsSelectorTest {

    @testSetup private static void testSetup() {
        Case c = DataFactoryCase.createClaims(1)[0];
        ObjectAuditTrail__c o1 = new ObjectAuditTrail__c();
        o1.caseId__c = c.Id;
        o1.AuditTrailType__c = 'CLAIM_SOLUTION';
        o1.Name = 'Case1';
        o1.SupplyReplacement__c = true;
        o1.SettlementAmount__c = 1000;
        insert o1;
    }

    @isTest private static void test001() {

        Case c = [select id from Case limit 1];

        DateTime start = System.Now();
        while(System.Now().getTime()< start.getTime()+2000){} //Delay

        ObjectAuditTrail__c o2 = new ObjectAuditTrail__c();
        o2.caseId__c = c.Id;
        o2.AuditTrailType__c = 'CLAIM_SOLUTION';
        o2.Name = 'Case2';
        o2.SupplyReplacement__c = true;
        o2.SettlementAmount__c = 2000;
        insert o2;

        ObjectAuditTrailsSelector selector = new ObjectAuditTrailsSelector();
        Map<Id, ObjectAuditTrail__c> results = selector.getLastCaseTrail(new Set<Id>{c.Id}, 'CLAIM_SOLUTION');
        ObjectAuditTrail__c lastTrail = results.get(c.Id);
        Assert.areEqual(lastTrail.Id, o2.Id);
    }

}