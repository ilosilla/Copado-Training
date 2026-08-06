@isTest
public with sharing class UserCommonsTest {
    @TestSetup
    static void makeData(){
        TestUtils.enableTriggers();

        List<Account> accsList = DataFactoryAccount.createAccounts(3);
        DataFactoryOpportunity.createRetailOpportunities(accsList, 1);
        SystemSettings.SAPConnectionDown = true;
    }
    
    @isTest static void getStandardUserPricebook() {
        Pricebook2 result = Usercommons.getStandardUserPricebook(UserInfo.getUserId());
        System.assertEquals(null, result, 'No debería haber encontrado un Pricebook'); 
    }
    
    @isTest static void hasSapConnectionUser() {
        User commonUser = DataFactoryUser.createUKUser();
        System.runAs(commonUser) {
            SystemSettings.SAPConnectionDown = true;
            Boolean result = Usercommons.hasSAPConnection();
            System.assertEquals(result, false, 'Shouldn\'t have SAP connection'); 
            SystemSettings.SAPConnectionDown = false;
            result = Usercommons.hasSAPConnection();
            System.assertEquals(result, true, 'Should have SAP connection'); 
        }
        SystemSettings.SAPConnectionDown = true;
        Boolean result2 = Usercommons.hasSAPConnection();
        System.assertEquals(result2, UserUtils.isTester(), 'Should have SAP connection'); 
        SystemSettings.SAPConnectionDown = false;
        result2 = Usercommons.hasSAPConnection();
        System.assertEquals(result2, true, 'Should have SAP connection'); 
    }

    @isTest static void isPriceManagerApprover() {
        User usr = DataFactoryUser.createUKUser();
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
        System.assertEquals(UserCommons.isPriceManager(UserInfo.getUserId(), opp.Id), true, 'Admin is always manager');
        System.assertEquals(UserCommons.isPriceApprover(UserInfo.getUserId(), opp.Id), true, 'Admin is always approver');
        System.runAs(usr) {
            List<Account> accsList = DataFactoryAccount.createAccounts(3);
            List<Opportunity> oppsListNoAdmin = DataFactoryOpportunity.createRetailOpportunities(accsList, 1);
            System.assertEquals(UserCommons.isPriceManager(usr.Id, oppsListNoAdmin[0].Id), false, 'The user shouldn\'t be Price Manager');
            System.assertEquals(UserCommons.isPriceApprover(usr.Id, oppsListNoAdmin[0].Id), false, 'The user shouldn\'t be Price Approver');
            System.assertEquals(UserCommons.isPriceApprover(usr.Id, null), false, 'The user shouldn\'t be Price Approver');
        }
    }

    @isTest static void hasAccessToSalesOrg() {
        User usr = DataFactoryUser.createUKUser();
        Boolean result = UserCommons.hasAccessToSalesOrg(usr.Id, usr.Default_Sales_Organization__c);
        System.assertEquals(result, true, 'The User should have acces to the sales org');
        result = UserCommons.hasAccessToSalesOrg(usr.Id, '888');
        System.assertEquals(result, false, 'The User shouldn\'t have acces to the sales org');
    }

    @isTest static void testHasCustomPermission1() {
        CustomPermission[] perms = [SELECT Id, DeveloperName FROM CustomPermission];
        Assert.areNotEqual(0, perms.size(), 'Nop custom permissions to test');
        UserCommons.hasCustomPermission(perms[0].DeveloperName);
        UserCommons.hasCustomPermission(UserInfo.getUserId(), perms[0].DeveloperName);
    }

    @isTest static void testHasPermissionSet() {
        List<PermissionSetAssignment> psaList = [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId()];
        Assert.isTrue(psaList.size() > 0, 'The user should have at least a permissions set');
        Boolean t1 = UserCommons.hasPermissionSet(UserInfo.getUserId(), psaList[0].PermissionSet.Name);
        Assert.isTrue(t1, 'User should have access to this PS');
        Boolean t2 = UserCommons.hasPermissionSet(UserInfo.getUserId(), 'FAKE_PERMISSION');
        Assert.isFalse(t2, 'User should NOT have access to this PS');
    }
}