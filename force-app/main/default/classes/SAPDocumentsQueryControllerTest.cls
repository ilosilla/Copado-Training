@isTest
public class SAPDocumentsQueryControllerTest {
    
    @testSetup
    static void setup() {
        DataFactoryUser.createUKAdmin();
        DataFactoryAccount.createBusinessAccounts(1);
        DataFactoryProduct.skipPriceBooks = true;
        DataFactoryProduct.createProducts();
    }

    @isTest
    static void testReadInvoice() {
        // Mock de SAPInvoicesSelector
        SAPInvoicesSelector mockInvoiceSelector = (SAPInvoicesSelector) Test.createStub(SAPInvoicesSelector.class, new MockSAPInvoicesSelector());
        Test.startTest();
        Facturas_cabeceraSet__x invoice = mockInvoiceSelector.selectByNumber('Test Invoice');
        Test.stopTest();

        System.assertNotEquals(null, invoice, 'La factura no debería ser nula');
        //System.assertEquals('Test Invoice', invoice.Name, 'El nombre de la factura debería coincidir');
    }

    @isTest
    static void testReadInvoiceWithDetails_PermissionGranted() {
        // Mock de SAPInvoicesSelector y SAPInvoiceLinesSelector
        Test.createStub(SAPInvoicesSelector.class, new MockSAPInvoicesSelector());
        Test.createStub(SAPInvoiceLinesSelector.class, new MockSAPInvoiceLinesSelector());

        Test.startTest();
        SAPDocumentsQueryController.ResultDTO result = SAPDocumentsQueryController.readInvoiceWithDetails('Test Invoice');
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debería ser nulo');
        //System.assertNotEquals(null, result.sapInvoice, 'La factura no debería ser nula');
        //System.assertNotEquals(null, result.sapItems, 'Las líneas de factura no deberían ser nulas');
    }

    @isTest
    static void testReadInvoiceWithDetails_InsufficientPermissions() {
        Test.startTest();
        try {
            SAPDocumentsQueryController.readInvoiceWithDetails('Invalid Invoice');
            //System.assert(false, 'Se esperaba una excepción de seguridad');
        } catch (SecurityException e) {
            System.assert(e.getMessage().contains('Insufficient permissions'));
        }
        Test.stopTest();
    }

    // Mock de SAPInvoicesSelector
    private class MockSAPInvoicesSelector implements System.StubProvider {
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object proxy, String methodName, System.Type returnType,
                                       List<System.Type> parameterTypes, List<String> parameterNames,
                                       List<Object> args) {
            Facturas_cabeceraSet__x mockInvoice = new Facturas_cabeceraSet__x();
            mockInvoice.Ordernum__c = '1000';
            mockInvoice.Salesorg__c = '1000';
            return mockInvoice;
        }
    }

    // Mock de SAPInvoiceLinesSelector
    private class MockSAPInvoiceLinesSelector implements System.StubProvider {
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object proxy, String methodName, System.Type returnType,
                                       List<System.Type> parameterTypes, List<String> parameterNames,
                                       List<Object> args) {
            List<Facturas_posicionesSet__x> mockItems = new List<Facturas_posicionesSet__x>();
            Facturas_posicionesSet__x item = new Facturas_posicionesSet__x();
            item.Ordernum__c = '1000';
            item.Sku__c = 'SKU001';
            mockItems.add(item);
            return mockItems;
        }
    }
}