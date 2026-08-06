@isTEst public class SAPInvoiceHeaderTest {
    
    @isTest private static void test001() {
        Facturas_cabeceraSet__x cab = new Facturas_cabeceraSet__x();
        cab.Ordernum__c = '111';
        cab.Orderdate__c = System.now();
        cab.Ddate__c = System.now();
        cab.BillTo__c = '232';
        SAPInvoiceHeader hdr = new SAPInvoiceHeader(cab);
        System.assertEquals(cab.Ordernum__c, hdr.docNumber, 'Invoice number should be equal');
    }
}