@isTest public class DataFactorySAPSalesDocsTest {

    @isTest private static void test001() {
        DataFactoryAccount.createBusinessAccounts(1);
        DataFactoryProduct.createProducts();
        DataFactorySAPSalesDocs df = new DataFactorySAPSalesDocs();
        List<SObject> l1 = (List<SObject>) df.getInvoiceHeaders(new Set<String> {'0001'});
        Assert.isTrue(l1.size() > 0, 'A non-empy list should have been returned');

        List<SObject> l2 = (List<SObject>) df.getInvoiceLines(new Set<String> {'0001'});
        Assert.isTrue(l2.size() > 0, 'A non-empy list should have been returned');
    }
}