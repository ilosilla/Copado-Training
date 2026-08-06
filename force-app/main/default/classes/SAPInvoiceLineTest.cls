@isTest public class SAPInvoiceLineTest {

    @isTest private static void test001() {

        Facturas_posicionesSet__x pos = new Facturas_posicionesSet__x();
        pos.Orderlin__c = '00001';
        pos.Fecha_Entrega__c = SYstem.now();

        SAPInvoiceLine line = new SAPInvoiceLine(pos);
        System.assertEquals(1, line.docLine, 'Line number should be 1');

    }
}