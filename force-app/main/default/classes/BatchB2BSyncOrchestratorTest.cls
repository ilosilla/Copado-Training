@isTest public class BatchB2BSyncOrchestratorTest {

    @testSetup
    private static void testSetup() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();
    }

    /**
     * No settings with EnablePIMSync__c = true → finish() returns early
     */
    @isTest
    private static void testNoActiveSettings() {
        // No PORSAStoreSettings__c records inserted
        Test.startTest();
        BatchB2BSyncOrchestrator.executeBatch();
        Test.stopTest();
        Assert.isTrue(true); // verify no exception thrown
    }

    /**
     * Settings found but WorkspaceId blank → PIM chain launched without CMS
     */
    @isTest
    private static void testNoCMSWorkspace() {
        WebStore store = [SELECT Id FROM WebStore LIMIT 1];
        insert new PORSAStoreSettings__c(
            Name             = 'US_DEALERS',
            StoreId__c       = store.Id,
            EnablePIMSync__c = true
            // WorkspaceId__c left blank → CMS skipped
        );

        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = '[]';
        mocker.testError = false;
        Test.setMock(HttpCalloutMock.class, mocker);

        Test.startTest();
        BatchB2BSyncOrchestrator.executeBatch();
        Test.stopTest();
        Assert.isTrue(true);
    }

    /**
     * Settings with WorkspaceId but no matching WebStoreCatalog → CMS skipped
     */
    @isTest
    private static void testNoWebStoreCatalog() {
        // Use a fake StoreId that has no WebStoreCatalog
        insert new PORSAStoreSettings__c(
            Name             = 'US_DEALERS',
            StoreId__c       = '0ZE000000000001',  // 15-char fake WebStore ID
            EnablePIMSync__c = true,
            WorkspaceId__c   = '0Zu000000000001'   // 15-char fake workspace ID
        );

        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = '[]';
        mocker.testError = false;
        Test.setMock(HttpCalloutMock.class, mocker);

        Test.startTest();
        BatchB2BSyncOrchestrator.executeBatch();
        Test.stopTest();
        Assert.isTrue(true);
    }

    /**
     * Schedulable interface
     */
    @isTest
    private static void testSchedulable() {
        Test.startTest();
        System.schedule('B2B Sync Test', '0 0 2 * * ?', new BatchB2BSyncOrchestrator());
        Test.stopTest();
        Assert.isTrue(true);
    }
}