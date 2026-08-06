@IsTest
private class BusinessStructureCommonsTest {

    @IsTest
    static void testRedirectedSalesOrgCodes() {
        // Casos con redirección esperada
        Assert.areEqual('514', BusinessStructureCommons.getRedirectedSalesOrg('504'), '504 should redirect to 514');
        Assert.areEqual('517', BusinessStructureCommons.getRedirectedSalesOrg('507'), '507 should redirect to 517');
        Assert.areEqual('231', BusinessStructureCommons.getRedirectedSalesOrg('218'), '218 should redirect to 231');
    }

    @IsTest
    static void testNonRedirectedSalesOrgCodes() {
        // Casos sin redirección definida, debe devolver el mismo valor
        Assert.areEqual('999', BusinessStructureCommons.getRedirectedSalesOrg('999'), '999 should not redirect');
        Assert.areEqual('101', BusinessStructureCommons.getRedirectedSalesOrg('101'), '101 should not redirect');
    }

    @IsTest static void testGetSalesOrgByPlant() {
        String org = BusinessStructureCommons.getSalesOrgByPlant('502');
        Assert.isNull(org, 'No org expected ion test');
    }

}