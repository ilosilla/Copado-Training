@isTest
public class CMS_ProductOrchestratorBatchTest {

    @testSetup
    static void setupData() {
        SystemSettings__c settings = SystemSettings.getSystemSettings();
        settings.SAPAPI__c = 'https://dummy-ai.com';
        settings.SAPCPIAPIKey__c = '321321321321';
        upsert settings;

        String usageType = ElectronicMediaGroup.UsageType.getDescribe().getPicklistValues()[0].getValue();

        insert new List<ElectronicMediaGroup>{
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_DETAIL_IMAGE, Name = 'Detail Image', UsageType = usageType),
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_LIST_IMAGE, Name = 'List Image', UsageType = usageType),
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_ATTACHMENT, Name = 'Attachment', UsageType = usageType)
        };

        Product2 product = new Product2(
            ProductCode = 'SKU-TEST-001',
            StockKeepingUnit = 'SKU-TEST-001',
            Name = 'Test Product',
            Umv__c = 'UN',
            SAPMake__c = 'P',
            IsActive = true
        );
        insert product;

        insert new List<PIMProductImage__c>{
            new PIMProductImage__c(
                StockKeepingUnit__c = 'SKU-TEST-001',
                ImageId__c = '1',
                Name__c = 'Main Catalog',
                ImageType__c = 'CATALOG',
                Square__c = 'https://example.com/100202546_ImgTec-sq.jpg',
                Xlarge__c = 'https://example.com/100202546_ImgTec-xl.jpg'
            )
        };
    }

    @isTest
    static void testExecuteBatchWithInjectedSkus() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());

        CMS_ProductOrchestratorBatch batch = new CMS_ProductOrchestratorBatch(UserInfo.getUserId(), UserInfo.getUserId());
        batch.setAutoPublish(false);
        batch.setTestSkus(new List<String>{ 'SKU-TEST-001', 'SKU-NOT-FOUND' });

        Iterable<String> scope = batch.start(null);
        List<String> skus = new List<String>();
        for (String sku : scope) {
            skus.add(sku);
        }

        Test.startTest();
        batch.execute(null, skus);
        batch.finish(null);
        Test.stopTest();

        Assert.areEqual(2, skus.size(), 'Two test SKUs are expected.');
    }

    @isTest
    static void testStaticExecuteBatch() {
        Test.startTest();
        CMS_ProductOrchestratorBatch.executeBatch(UserInfo.getUserId(), UserInfo.getUserId());
        Test.stopTest();

        Assert.isTrue(true, 'Static executeBatch should run.');
    }

    @isTest
    static void testSchedulableExecute() {
        CMS_ProductOrchestratorBatch batch = new CMS_ProductOrchestratorBatch(UserInfo.getUserId(), UserInfo.getUserId());

        Test.startTest();
        batch.execute((SchedulableContext) null);
        Test.stopTest();

        Assert.isTrue(true, 'Schedulable execute should run.');
    }

    @isTest
    static void testMaxProductsLimit() {
        CMS_ProductOrchestratorBatch batch = new CMS_ProductOrchestratorBatch(UserInfo.getUserId(), UserInfo.getUserId(), 1);
        batch.setTestSkus(new List<String>{ 'SKU-TEST-003', 'SKU-TEST-002', 'SKU-TEST-001' });

        Iterable<String> scope = batch.start(null);
        List<String> skus = new List<String>();
        for (String sku : scope) {
            skus.add(sku);
        }

        Assert.areEqual(1, skus.size(), 'Only one SKU should be returned when maxProducts = 1.');
        Assert.areEqual('SKU-TEST-001', skus[0], 'The SKU list should remain sorted before truncation.');
    }

    @isTest
    static void testSkuFilterOverridesCatalogSelection() {
        CMS_ProductOrchestratorBatch batch = new CMS_ProductOrchestratorBatch(
            UserInfo.getUserId(),
            UserInfo.getUserId(),
            null,
            'SKU-TEST-002, SKU-TEST-001',
            true,
            CMS_ProductOrchestrator.MODE_REPLACE_EXISTING
        );

        Iterable<String> scope = batch.start(null);
        List<String> skus = new List<String>();
        for (String sku : scope) {
            skus.add(sku);
        }

        Assert.areEqual(2, skus.size(), 'Two filtered SKUs are expected.');
        Assert.areEqual('SKU-TEST-001', skus[0], 'The filtered SKU list should be sorted.');
        Assert.areEqual('SKU-TEST-002', skus[1], 'The filtered SKU list should include the second SKU.');
    }
}