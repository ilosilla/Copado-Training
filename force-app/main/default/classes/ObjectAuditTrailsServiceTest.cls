/**
 * @author         Ramón Prades
 * @date           February 2024
 * @group          Tests
 * @description    Test class
*/
@isTest public class ObjectAuditTrailsServiceTest {

    @testSetup private static void testSetup() {
        DataFactoryCase.autoInsert = false;
        Case c = DataFactoryCase.createClaims(1)[0];
        c.SupplyReplacement__c = true;
        c.Compensation__c = 1000;
        insert c;
        ObjectAuditTrailsService.logClaimSolutionChanged(new List<Case>{c});
    } // testSetup

    @isTest private static void test001() {
        Case c = [select Id from Case limit 1];
        ObjectAuditTrail__c[] trails = [select Id from ObjectAuditTrail__c];
        Assert.areEqual(1, trails.size());

        c = new CasesSelector().selectById(new Set<Id>{c.Id})[0];
        ObjectAuditTrailsService.logClaimSolutionChanged(new List<Case> {c});
        ObjectAuditTrail__c[] trails1 = [select Id from ObjectAuditTrail__c];
        Assert.areEqual(1, trails1.size());

        c.SupplyReplacement__c = false;
        c.Compensation__c = 500;
        update c;
        ObjectAuditTrailsService.logClaimSolutionChanged(new List<Case> {c});
        ObjectAuditTrail__c[] trails2 = [select Id from ObjectAuditTrail__c];
        Assert.areEqual(2, trails2.size());    
    }
}