@isTest public class CasesDomainTest {

    @testSetup private static void testSetup() {
        SAPCasesSettings__c settings = new SAPCasesSettings__c();
        settings.Name = '502';
        settings.COL_ApproverEmails__c = 'test@testdomain.cxm';
        //settings.CLAIM_AssignTo__c = 'rprades@porcelanosagrupo.com';
        settings.CLAIM_NotifyNewToOwner__c = true;
        settings.CLAIM_QueueDevName__c = 'dummy_queue';
        insert settings;          
        DataFactoryUser.createUKAdmin(); 
    }

    @isTest public static void testGetSettings() {
        SAPCasesSettings__c settings = CasesDomain.getSAPSettings('502');
        Assert.areEqual('502', settings.Name);
    }

    @isTest public static void testGetSettings2() {
        SAPCasesSettings__c settings = new SAPCasesSettings__c();
        settings.Name = '605';
        settings.COL_ApproverEmails__c = 'test@testdomain.cxm';
        //settings.CLAIM_AssignTo__c = 'rprades@porcelanosagrupo.com';
        settings.CLAIM_NotifyNewToOwner__c = true;
        settings.CLAIM_QueueDevName__c = 'dummy_queue';
        insert settings;          
        Test.startTest();
        SAPCasesSettings__c settings2 = CasesDomain.getSAPSettings('605', '64455664455');
        Test.stopTest();
        Assert.areEqual('605', settings2.Name, '605 expected');
    }


    @isTest public static void testGetSettings3() {
        Test.startTest();
        SAPCasesSettings__c settings2 = CasesDomain.getSAPSettings('605', '78798797898');
        Test.stopTest();
        Assert.isNull(settings2, 'Null expected');
    }

    @isTest public static void testCollections() {
        Case col = DatafactoryCase.createCollections(1)[0];
        col.Status = CasesDomain.STATUS_APPROVED;
        update col;
    }

    @isTest public static void testCollections2() {
        String error = null;
        try {
            Case col = DatafactoryCase.createCollections(1)[0];
            col.Status = CasesDomain.STATUS_COLLECTED;
            update col;
        } catch(Exception ex) {
            error = ex.getMessage();
        }
        Assert.isNotNull(error, 'An exception was espected');
    }

    @isTest private static void testClaimTriggers() {
        Test.startTest();
        DataFactoryCase.autoInsert = false;
        Case c = DataFactoryCase.createClaims(1)[0];
        c.SalesOrg__c = '502';
        insert c;
        DataFactoryCase.autoInsert = true;
        Test.stopTest();

        Case[] claims = [select Id, SalesOrg__c, CUrrencyIsoCode from Case where IsClaim__c = true];
        Assert.isTrue(claims.size() > 0, 'There should be a claim');
        Case claim = claims[0];

        // Change owner
        User u = [select Id, Name, Email from User where Id != :UserInfo.getUserId()][0];
        claim.OwnerId = u.Id;
        update claim;

        // Record a proposal
        claim.Compensation__c = 1000;
        claim.Liability__c = PicklistCommons.getKeysList(Case.Liability__c)[0];
        claim.Warranty__c = PicklistCommons.getKeysList(Case.Warranty__c)[0];
        claim.Status = CasesDomain.CLAIM_STATUS_PROPOSAL;
        update claim;

        ObjectAuditTrail__c trail = new ObjectAuditTrailsSelector().getLastCaseTrail(claim.Id, 'CLAIM_SOLUTION');
        Assert.isNotNull(trail, 'An audit trail should have been saved');
        
        // Accept the proposal
        claim.Status = CasesDomain.CLAIM_STATUS_AGREEMENT;
        update claim;

        Case c2 = new CasesSelector().selectById(new Set<Id>{claim.Id})[0];
        Assert.isNotNull(c2.CustomerAgreed__c, 'The case should have been agreed');        

    }

    @isTest private static void testClaimOwner() {
        User u = DataFactoryUser.createUKUsers(1)[0];
        System.runAs(u) {
            Test.startTest();
            DataFactoryCase.autoInsert = false;
            Case c = DataFactoryCase.createClaims(1)[0];
            c.SalesOrg__c = '502';
            insert c;
            DataFactoryCase.autoInsert = true;
            Test.stopTest();
        }
        Case[] claims = [select Id, OwnerId, SalesOrg__c, CurrencyIsoCode from Case where IsClaim__c = true];        
        Assert.areEqual(u.Id, claims[0].OwnerId, 'The owner should be the current user ');
    }

            
}