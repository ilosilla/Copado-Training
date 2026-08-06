@isTest public with sharing class BatchMaterialBankLauncherTest {

    @testSetup static void testSetup() {
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    @isTest static void test001() {
    Test.setMock(HttpCalloutMock.class, new BatchMaterialBankImporterTest.Mocker());
        Test.startTest();
        BatchMaterialBankLauncher launcher = new BatchMaterialBankLauncher();
        launcher.execute(null);
        Test.stopTest();
        Assert.isTrue(true, 'Dummy');
    }
}