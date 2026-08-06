@IsTest
private class B2B_SalesDocumentsControllerTest {

    @testSetup private static void setup() {
        DataFactoryAccount.createAccounts(1);
    }

    @IsTest public static void testGetOpenOrders() {
        Account acc = [SELECT Id, SAP_Id__c FROM Account LIMIT 1];
        if (acc.SAP_Id__c == null) {
            acc.SAP_Id__c = '1000001';
            update acc;
        }
        Assert.isNotNull(acc.SAP_Id__c, 'Test account should have SAP Id for this test');
        User u = [select Id, Default_Sales_Organization__c from User where Id = :UserInfo.getUserId() limit 1];
        Assert.isNotNull(u.Default_Sales_Organization__c, 'Test user should have Default Sales Organization for this test');
        Test.startTest();
        Pedidos_cabeceraSet__x mockData = SAPOrderReaderTest.mockSAPOrderHeader('1000000');
        B2BOrdersReader.mockData = new List<Pedidos_cabeceraSet__x>{ mockData };
        List<B2B_SalesDocumentsController.OrderRowDTO> results = B2B_SalesDocumentsController.getOpenOrders(acc.Id, 10);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Expected 5 orders returned');
    }

    @IsTest public static void testGetOrderHistory_invoicedOrdersOnly() {
        Account acc = [SELECT Id, SAP_Id__c FROM Account LIMIT 1];
        if (acc.SAP_Id__c == null) {
            acc.SAP_Id__c = '1000001';
            update acc;
        }

        // Mock: one invoiced order (OpenF = C) and one open (OpenF = A)
        Pedidos_cabeceraSet__x invoiced = SAPOrderReaderTest.mockSAPOrderHeader('14772343');
        invoiced.OpenF__c = 'C';
        invoiced.Customer__c = acc.SAP_Id__c;

        Pedidos_cabeceraSet__x open = SAPOrderReaderTest.mockSAPOrderHeader('14778802');
        open.OpenF__c = 'A';
        open.Customer__c = acc.SAP_Id__c;

        B2BOrdersReader.mockData = new List<Pedidos_cabeceraSet__x>{ invoiced, open };

        Test.startTest();
        List<B2B_SalesDocumentsController.OrderRowDTO> results =
            B2B_SalesDocumentsController.getOrderHistory(acc.Id, 'THIS_YEAR', 50);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Only invoiced orders (OpenF=C) should be returned');
        Assert.areEqual('14772343', results[0].sapNumber, 'SAP number mismatch');
        Assert.isNull(results[0].invoiceNumber, 'Invoice number should be null — no External Object data in tests');
    }

    @IsTest public static void testGetOrderHistory_empty() {
        Account acc = [SELECT Id, SAP_Id__c FROM Account LIMIT 1];
        if (acc.SAP_Id__c == null) {
            acc.SAP_Id__c = '1000001';
            update acc;
        }
        B2BOrdersReader.mockData = new List<Pedidos_cabeceraSet__x>();

        Test.startTest();
        List<B2B_SalesDocumentsController.OrderRowDTO> results =
            B2B_SalesDocumentsController.getOrderHistory(acc.Id, 'THIS_YEAR', 50);
        Test.stopTest();

        Assert.areEqual(0, results.size(), 'Expected empty result');
    }

    @IsTest public static void testGetOrderDetail() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order o = DataFactoryOrder.createOrders(acc.Id, 1)[0];
        //Test.createStub(SAPOrderReader.class, new SAPOrderReaderTest.StubbedSAPOrderReader());       
        B2B_SalesDocumentsController.OrderDetailDTO detail = B2B_SalesDocumentsController.getOrderDetail(o.Id, null, acc.Id);
        System.assertNotEquals(null, detail.order, 'Expected order details to be returned');
    }
 
}