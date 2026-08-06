@isTest public with sharing class SAPInvoicesSelectorTest {
    
    @isTest public static void getSelectClause() {
        SAPInvoicesSelector selector = new SAPInvoicesSelector();
        String result = selector.getSelectClause();
        System.assertNotEquals(0, result.length(), 'There should be fields');
    }

    @isTest (SeeAllData=true) private static void selectByNumber1() {
        Set<String> ids = new Set<String>();
        ids.add('123');
        SAPInvoicesSelector selector = new SAPInvoicesSelector();
        List<Facturas_cabeceraSet__x> result = selector.selectByNumber(ids);
        Assert.isTrue(result.size() > 0, 'Some records expected!');
    }

    @isTest (SeeAllData=true) private static void selectByNumber2() {
        Boolean exc = false;
        try {
            SAPInvoicesSelector selector = new SAPInvoicesSelector();
            Facturas_cabeceraSet__x result = selector.selectByNumber('123');
        } catch(ObjectNotFoundException e) {
            exc = true;
        }
        System.assertEquals(false, exc, 'Exception not expected');
    }

}