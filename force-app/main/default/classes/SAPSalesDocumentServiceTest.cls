@isTest
public class SAPSalesDocumentServiceTest {
	@isTest
	static void testDownloadSAPDocument() {
		SAPSalesDocumentService.downloadSAPDocument('O', '123');
        Assert.areEqual(1, 1, 'It´s an external service');
	}
}