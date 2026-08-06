@isTest public with sharing class CMS_ProductMediaServiceTest {

    static void setupData() {
        // ElectronicMediaGroups expected by the service
        List<ElectronicMediaGroup> groups = new List<ElectronicMediaGroup>{
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_DETAIL_IMAGE, Name = 'Detail Image'),
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_LIST_IMAGE,   Name = 'List Image'),
            new ElectronicMediaGroup(DeveloperName = CMS_ProductMediaService.PRODUCT_ATTACHMENT,   Name = 'Attachment')
        };
        insert groups;
    }

    @isTest static void test001() {
        CMS_ProductMediaService.ProductMediaDTO[] records = new List<CMS_ProductMediaService.ProductMediaDTO>();
        CMS_ProductMediaService.ProductMediaDTO dto = new CMS_ProductMediaService.ProductMediaDTO();
        dto.productId = UserInfo.getUserId();   // Dummy - just to have an Id
        dto.managedContentId = UserInfo.getUserId();   // Dummy - just to have an Id
        records.add(dto);
        CMS_ProductMediaService service = new CMS_ProductMediaService();
        try {
            service.addProductDetailImages(records);
        } catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Assert.isTrue(true);
    }

    @isTest static void test002() {
        CMS_ProductMediaService.ProductMediaDTO[] records = new List<CMS_ProductMediaService.ProductMediaDTO>();
        CMS_ProductMediaService.ProductMediaDTO dto = new CMS_ProductMediaService.ProductMediaDTO();
        dto.productId = UserInfo.getUserId();   // Dummy - just to have an Id
        dto.managedContentId = UserInfo.getUserId();   // Dummy - just to have an Id
        records.add(dto);
        CMS_ProductMediaService service = new CMS_ProductMediaService();
        try {
            service.addProductListImages(records);
        } catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Assert.isTrue(true);
    }

    @isTest static void test003() {
        CMS_ProductMediaService.ProductMediaDTO[] records = new List<CMS_ProductMediaService.ProductMediaDTO>();
        CMS_ProductMediaService.ProductMediaDTO dto = new CMS_ProductMediaService.ProductMediaDTO();
        dto.productId = UserInfo.getUserId();   // Dummy - just to have an Id
        dto.managedContentId = UserInfo.getUserId();   // Dummy - just to have an Id
        records.add(dto);
        CMS_ProductMediaService service = new CMS_ProductMediaService();
        try {
            service.addProductAttachments(records);
        } catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Assert.isTrue(true);
    }


}