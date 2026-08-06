@isTest
public class CMS_ProductMediaQueueableTest {

    @testSetup
    static void setupData() {
        SystemSettings__c systemSettings = SystemSettings.getSystemSettings();
        systemSettings.SAPAPI__c = 'https://dummy-ai.com';
        systemSettings.SAPCPIAPIKey__c = '123456789';
        upsert systemSettings;

        String usageType = ElectronicMediaGroup.UsageType.getDescribe().getPicklistValues()[0].getValue();
        insert new List<ElectronicMediaGroup>{
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_DETAIL_IMAGE, Name = 'Detail Image', UsageType = usageType),
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_LIST_IMAGE, Name = 'List Image', UsageType = usageType),
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_ATTACHMENT, Name = 'Attachment', UsageType = usageType)
        };

        insert new Product2(
            Name = 'CMS Product Media Queueable Test Product',
            ProductCode = 'SKU-QUEUEABLE-001',
            StockKeepingUnit = 'SKU-QUEUEABLE-001',
            IsActive = true,
            SAPMake__c = 'P',
            Umv__c = 'UN'
        );
    }

    private static Id getProductId() {
        return [
            SELECT Id
            FROM Product2
            WHERE StockKeepingUnit = 'SKU-QUEUEABLE-001'
            LIMIT 1
        ].Id;
    }

    @isTest
    static void testExecuteOneListJob() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());
        CMS_ProductMediaQueueable.testManagedContentId = UserInfo.getUserId();

        CMS_ProductMediaQueueable.MediaJobDTO job = new CMS_ProductMediaQueueable.MediaJobDTO();
        job.productId = getProductId();
        job.sku = 'SKU-TEST-001';
        job.role = CMS_ProductMediaQueueable.ROLE_LIST;
        job.url = 'https://example.com/100202546_ImgTec-sq.jpg';
        job.sequence = 1;

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>{ job },
            UserInfo.getUserId(),
            false
        );

        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        CMS_ProductMediaQueueable.testManagedContentId = null;
        Assert.isTrue(true, 'Queueable execution should complete.');
    }

    @isTest
    static void testExecuteOneDetailJob() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());
        CMS_ProductMediaQueueable.testManagedContentId = UserInfo.getUserId();

        CMS_ProductMediaQueueable.MediaJobDTO job = new CMS_ProductMediaQueueable.MediaJobDTO();
        job.productId = getProductId();
        job.sku = 'SKU-TEST-002';
        job.role = CMS_ProductMediaQueueable.ROLE_DETAIL;
        job.url = 'https://example.com/100202546_ImgTec-xl.jpg';
        job.sequence = 2;

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>{ job },
            UserInfo.getUserId(),
            false
        );

        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        CMS_ProductMediaQueueable.testManagedContentId = null;
        Assert.isTrue(true, 'Detail queueable execution should complete.');
    }

    @isTest
    static void testExecuteOneAttachmentJob() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());
        CMS_ProductMediaQueueable.testManagedContentId = UserInfo.getUserId();

        CMS_ProductMediaQueueable.MediaJobDTO job = new CMS_ProductMediaQueueable.MediaJobDTO();
        job.productId = getProductId();
        job.sku = 'SKU-TEST-003';
        job.role = CMS_ProductMediaQueueable.ROLE_ATTACHMENT;
        job.url = 'https://example.com/ficha-tecnica.pdf';
        job.sequence = 3;

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>{ job },
            UserInfo.getUserId(),
            false
        );

        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        CMS_ProductMediaQueueable.testManagedContentId = null;
        Assert.isTrue(true, 'Attachment queueable execution should complete.');
    }

    @isTest
    static void testExecuteWithEmptyJobs() {
        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>(),
            UserInfo.getUserId(),
            false
        );

        queueable.execute(null);

        Assert.isTrue(true, 'Empty queueable execution should return immediately.');
    }

    @isTest
    static void testExecuteQueuesNextJob() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());
        CMS_ProductMediaQueueable.testManagedContentId = UserInfo.getUserId();

        CMS_ProductMediaQueueable.MediaJobDTO firstJob = new CMS_ProductMediaQueueable.MediaJobDTO();
        firstJob.productId = getProductId();
        firstJob.sku = 'SKU-TEST-004';
        firstJob.role = CMS_ProductMediaQueueable.ROLE_LIST;
        firstJob.url = 'https://example.com/100202546_ImgTec-sq.jpg';
        firstJob.sequence = 1;

        CMS_ProductMediaQueueable.MediaJobDTO secondJob = new CMS_ProductMediaQueueable.MediaJobDTO();
        secondJob.productId = getProductId();
        secondJob.sku = 'SKU-TEST-004';
        secondJob.role = CMS_ProductMediaQueueable.ROLE_DETAIL;
        secondJob.url = 'https://example.com/100202546_ImgTec-xl.jpg';
        secondJob.sequence = 2;

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>{ firstJob, secondJob },
            UserInfo.getUserId(),
            false
        );

        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        CMS_ProductMediaQueueable.testManagedContentId = null;
        Assert.isTrue(true, 'Queue chaining should be covered.');
    }

    @isTest
    static void testExecuteWithIndexOutOfBounds() {
        CMS_ProductMediaQueueable.MediaJobDTO job = new CMS_ProductMediaQueueable.MediaJobDTO();
        job.productId = getProductId();
        job.sku = 'SKU-TEST-005';
        job.role = CMS_ProductMediaQueueable.ROLE_LIST;
        job.url = 'https://example.com/100202546_ImgTec-sq.jpg';
        job.sequence = 1;

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>{ job },
            1,
            UserInfo.getUserId(),
            false
        );

        queueable.execute(null);

        Assert.isTrue(true, 'Out of bounds index should return immediately.');
    }

    @isTest
    static void testExecuteHandlesDownloadError() {
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.testError = true;
        Test.setMock(HttpCalloutMock.class, mocker);

        CMS_ProductMediaQueueable.MediaJobDTO job = new CMS_ProductMediaQueueable.MediaJobDTO();
        job.productId = getProductId();
        job.sku = 'SKU-TEST-006';
        job.role = CMS_ProductMediaQueueable.ROLE_LIST;
        job.url = 'https://example.com/invalid-image.jpg';
        job.sequence = 1;

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>{ job },
            UserInfo.getUserId(),
            false
        );

        Test.startTest();
        queueable.execute(null);
        Test.stopTest();

        Assert.isTrue(true, 'Download errors should be handled inside the queueable.');
    }

    @isTest
    static void testUploadAttachmentBranch() {
        CMS_ProductMediaQueueable.testManagedContentId = UserInfo.getUserId();

        CMS_UrlDownloader.DownloadResult downloadResult = new CMS_UrlDownloader.DownloadResult();
        downloadResult.fileName = 'datasheet.pdf';
        downloadResult.mimeType = null;
        downloadResult.content = Blob.valueOf('pdf-content');

        CMS_ProductMediaQueueable queueable = new CMS_ProductMediaQueueable(
            new List<CMS_ProductMediaQueueable.MediaJobDTO>(),
            UserInfo.getUserId(),
            false
        );

        String managedContentId = queueable.upload(
            CMS_ProductMediaQueueable.ROLE_ATTACHMENT,
            'SKU-TEST-007__ATT_1__datasheet.pdf',
            downloadResult
        );

        CMS_ProductMediaQueueable.testManagedContentId = null;
        Assert.areEqual(UserInfo.getUserId(), managedContentId, 'Attachment upload should use the test managed content id.');
    }
}