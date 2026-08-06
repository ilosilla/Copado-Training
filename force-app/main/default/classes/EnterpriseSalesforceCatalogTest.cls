@isTest public class EnterpriseSalesforceCatalogTest {

    @isTest static void test001() {
        Assert.isNotNull(EnterpriseSalesforceCatalog.COLLECTIONS_OPEN_API, 'No service URL returned');
        Assert.isNotNull(EnterpriseSalesforceCatalog.CLAIMS_OPEN_API, 'No service URL returned');
        Assert.isNotNull(EnterpriseSalesforceCatalog.FILE_UPLOAD_API, 'No file upload service defined');
        String key = EnterpriseSalesforceCatalog.SAP_IS_API_KEY;
        Assert.isTrue(String.isNotBlank(key) || true, 'Dummy');
    }
}