@isTest private class SalesRelationshipUtilsTest {

    @isTest private static void testCreateDefaultSalesRelations() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }
    
    @isTest private static void testCreateDefaultSalesRelationsUS() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'US';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }
    @isTest private static void testCreateDefaultSalesRelationsCA() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'CA';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateDefaultSalesRelationsCH() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'CH';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateDefaultSalesRelationsSE() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'SE';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateDefaultSalesRelationsIL() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'IL';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateDefaultSalesRelationsCL() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'CL';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateDefaultSalesRelationsAU() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'AU';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateDefaultSalesRelationsGB() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        UsersSelector selector = new UsersSelector();
        user usr = selector.selectById(new Set<Id> {UserInfo.getUserId()})[0];
        usr.CountryCode = 'GB';
        Sales_Relationship__c sr = SalesRelationshipUtils.createDefaultSalesRelations(acc, USR, 'reason');
        String codeSR = SalesRelationshipUtils.getSalesRelName(sr, 'GB');
        System.assertEquals(usr.Default_Sales_Organization__c, sr.Sales_Org__c, 'Sales Org should be the same');
    }

    @isTest private static void testCreateAutomaticOpportunity() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        Opportunity opp = SalesRelationshipUtils.createAutomaticOpportunity(acc);
        System.assertEquals(acc.Id, opp.AccountId, 'Should be the same account');
    }

}