@isTest
public class CMS_ProductOrchestratorTest {

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

        Product2 product = DataFactoryProduct.createProducts()[0];
        product.StockKeepingUnit = 'SKU-TEST-001';
        update product;

        insert new List<PIMProductImage__c>{
            new PIMProductImage__c(
                StockKeepingUnit__c = 'SKU-TEST-001',
                ImageId__c = '1',
                Name__c = 'AMB Catalog',
                ImageType__c = 'CATALOG',
                Square__c = 'https://example.com/P.AMB.0001-sq.jpg',
                Xlarge__c = 'https://example.com/P.AMB.0001-xl.jpg'
            ),
            new PIMProductImage__c(
                StockKeepingUnit__c = 'SKU-TEST-001',
                ImageId__c = '2',
                Name__c = 'Main Catalog',
                ImageType__c = 'CATALOG',
                Square__c = 'https://example.com/100202546_ImgTec-sq.jpg',
                Xlarge__c = 'https://example.com/100202546_ImgTec-xl.jpg'
            ),
            new PIMProductImage__c(
                StockKeepingUnit__c = 'SKU-TEST-001',
                ImageId__c = '3',
                Name__c = 'Setting One',
                ImageType__c = 'SETTING',
                Square__c = 'https://example.com/P.AMB.0002-sq.jpg',
                Xlarge__c = 'https://example.com/P.AMB.0002-xl.jpg'
            ),
            new PIMProductImage__c(
                StockKeepingUnit__c = 'SKU-TEST-001',
                ImageId__c = '4',
                Name__c = 'Ficha técnica',
                ImageType__c = 'OTHER',
                ElementUrl__c = 'https://example.com/ficha-tecnica.pdf'
            )
        };
    }

    @isTest
    static void testExecuteSelectsMediaAsExpected() {
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());

        CMS_ProductOrchestrator service = new CMS_ProductOrchestrator('SKU-TEST-001', UserInfo.getUserId());
        service.setAutoPublish(false);

        Test.startTest();
        CMS_ProductOrchestrator.ResultDTO result = service.execute();
        Test.stopTest();

        Assert.isTrue(result.productFound, 'The product should be found.');
        Assert.areEqual('https://example.com/100202546_ImgTec-sq.jpg', result.selectedListUrl, 'The list image should prefer the first CATALOG image without .AMB.');
        Assert.areEqual(3, result.selectedDetailUrls.size(), 'All detail images should be selected.');
        Assert.areEqual('https://example.com/100202546_ImgTec-xl.jpg', result.selectedDetailUrls[0], 'The featured PDP image should be the same image chosen for PLP.');
        Assert.areEqual(1, result.selectedAttachmentUrls.size(), 'One attachment should be selected.');
        Assert.areEqual('https://example.com/ficha-tecnica.pdf', result.selectedAttachmentUrls[0], 'The OTHER image should become an attachment.');
    }

    @isTest
    static void testExecuteReturnsErrorWhenProductDoesNotExist() {
        CMS_ProductOrchestrator service = new CMS_ProductOrchestrator('SKU-NOT-FOUND', UserInfo.getUserId());
        service.setAutoPublish(false);

        CMS_ProductOrchestrator.ResultDTO result = service.execute();

        Assert.isFalse(result.productFound, 'The product should not be found.');
        Assert.areEqual(1, result.errors.size(), 'A single error is expected.');
    }

    @isTest
    static void testExecuteExtendedLogReturnsDebugLines() {
        CMS_ProductOrchestrator service = new CMS_ProductOrchestrator('SKU-TEST-001', UserInfo.getUserId());
        service.setAutoPublish(false);
        service.setExtendedLog(true);

        CMS_ProductOrchestrator.ResultDTO result = service.execute();

        Assert.isTrue(result.debugLines.size() > 0, 'Extended log should capture decision traces.');
    }

    @isTest
    static void testExecuteReplaceExistingDeletesCurrentProductMedia() {
        CMS_ProductOrchestrator service = new CMS_ProductOrchestrator('SKU-TEST-001', UserInfo.getUserId());
        service.setAutoPublish(false);
        service.setExtendedLog(true);
        service.setTestExistingMedia(true, true, true);

        CMS_ProductOrchestrator.ResultDTO result = service.execute();

        Assert.isFalse(result.listImageSkipped, 'PLP should be processed in replace mode.');
        Assert.isFalse(result.detailImagesSkipped, 'PDP should be processed in replace mode.');
        Assert.isFalse(result.attachmentsSkipped, 'Attachments should be processed in replace mode.');
        Assert.isTrue(
            result.debugLines.contains('Deleting existing PLP ProductMedia records: 1'),
            'Replace mode should plan deletion of existing PLP media.'
        );
    }

    @isTest
    static void testExecuteInsertMissingKeepsCurrentProductMedia() {
        CMS_ProductOrchestrator service = new CMS_ProductOrchestrator('SKU-TEST-001', UserInfo.getUserId());
        service.setAutoPublish(false);
        service.setMode(CMS_ProductOrchestrator.MODE_INSERT_MISSING);
        service.setTestExistingMedia(true, false, false);

        CMS_ProductOrchestrator.ResultDTO result = service.execute();

        Assert.isTrue(result.listImageSkipped, 'PLP should be skipped in insert missing mode when media already exists.');
    }

    @isTest
    static void testExecuteLimitsDetailImagesToSix() {
        List<PIMProductImage__c> extraImages = new List<PIMProductImage__c>();
        for (Integer i = 10; i < 20; i++) {
            extraImages.add(new PIMProductImage__c(
                StockKeepingUnit__c = 'SKU-TEST-001',
                ImageId__c = String.valueOf(i),
                Name__c = 'Setting ' + i,
                ImageType__c = 'SETTING',
                Xlarge__c = 'https://example.com/P.AMB.00' + String.valueOf(i) + '-xl.jpg'
            ));
        }
        insert extraImages;

        CMS_ProductOrchestrator service = new CMS_ProductOrchestrator('SKU-TEST-001', UserInfo.getUserId());
        service.setAutoPublish(false);

        CMS_ProductOrchestrator.ResultDTO result = service.execute();

        Assert.areEqual(6, result.selectedDetailUrls.size(), 'The number of detail images should be limited to six.');
    }
}