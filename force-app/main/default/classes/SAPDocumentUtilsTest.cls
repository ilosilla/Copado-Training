@isTest public with sharing class SAPDocumentUtilsTest {
    @isTest private static void getInvoiced() {
        Map<String, Double> theMap = SAPDocumentUtils.getInvoiced('111');
        System.AssertEquals(0, theMap.get('net'));
    }

    @isTest private static void isSamplesDocument() {
        Boolean samples = SAPDocumentUtils.isSamplesDocument('O', 'XXX', 0);
        System.assertEquals(true, samples, 'Should have been samples');

        samples = SAPDocumentUtils.isSamplesDocument('O', 'Z010', 10);
        System.assertEquals(true, samples, 'Should have been samples');

        samples = SAPDocumentUtils.isSamplesDocument('I', 'Z004', 10);
        System.assertEquals(true, samples, 'Should have been samples');

        samples = SAPDocumentUtils.isSamplesDocument('I', 'XXX', 10);
        System.assertEquals(false, samples, 'Should have not been samples');

        samples = SAPDocumentUtils.isSamplesDocument('O', 'XXX', 10);
        System.assertEquals(false, samples, 'Should have not been samples');
    }

    @isTest private static void isQuoteClosed() {
        Boolean status = SAPDocumentUtils.isQuoteClosed('A');
        System.assertEquals(false, status, 'Wrong calculation');
        status = SAPDocumentUtils.isQuoteClosed('C');
        System.assertEquals(true, status, 'Wrong calculation');
    }

    @isTest private static void isOrderClosed() {
        Boolean status = SAPDocumentUtils.isOrderClosed('A');
        System.assertEquals(false, status, 'Wrong calculation');
        status = SAPDocumentUtils.isOrderClosed('C');
        System.assertEquals(true, status, 'Wrong calculation');
    }

    @isTest private static void isQuotepartiallyClosed() {
        Boolean status = SAPDocumentUtils.isQuotePartiallyClosed('A');
        System.assertEquals(false, status, 'Wrong calculation');
        status = SAPDocumentUtils.isQuotePartiallyClosed('B');
        System.assertEquals(true, status, 'Wrong calculation');
    }

    @isTest private static void isOrderpartiallyClosed() {
        Boolean status = SAPDocumentUtils.isOrderPartiallyClosed('A');
        System.assertEquals(false, status, 'Wrong calculation');
        status = SAPDocumentUtils.isOrderPartiallyClosed('B');
        System.assertEquals(true, status, 'Wrong calculation');
    }

}