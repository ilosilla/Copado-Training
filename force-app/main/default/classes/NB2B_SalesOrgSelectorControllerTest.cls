@isTest
public class NB2B_SalesOrgSelectorControllerTest {
    @isTest
    static void testGetSalesOrgList() {
        NB2B_SalesOrgSelectorController.getSalesOrgList();
    }
    @isTest
    static void testSaveContactSalesOrg() {
        try {
            NB2B_SalesOrgSelectorController.saveContactSalesOrg('Test Sales Org');
        } catch (Exception e) {}
    }
}