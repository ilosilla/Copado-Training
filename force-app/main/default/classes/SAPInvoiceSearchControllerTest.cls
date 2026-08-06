@isTest public class SAPInvoiceSearchControllerTest {

    @isTest static void testReadInvoices() {
        SAPInvoiceSearchController.SearchDTO criteria = new SAPInvoiceSearchController.SearchDTO();
        criteria.salesOrg = '502';
        SAPInvoiceSearchController.SearchResultsDTO dto = SAPInvoiceSearchController.readInvoices(criteria);
        Assert.isNotNull(dto);

    }
}