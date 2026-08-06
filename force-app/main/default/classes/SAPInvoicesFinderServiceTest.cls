@isTest public with sharing class SAPInvoicesFinderServiceTest {

    @testSetup static void testSetup() {
        DataFactoryAccount.createAccounts(1);
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();
    }
    @isTest static void testFinder() {
        Account acc = [select Id, SAP_Id__c from Account limit 1];
        if (acc.SAP_Id__c == null) {
            acc.SAP_Id__c = '123321';
            update acc;
        }
        Product2 pro = [select Id, StockKeepingUnit from Product2 limit 1];
        if (pro.StockKeepingUnit == null) {
            pro.StockKeepingUnit = '1000000';
            update pro;
        }
        Test.startTest();
        SAPInvoicesFinderService finder = new SAPInvoicesFinderService();
        finder.setSalesOrg('502');
        finder.setAccountId(acc.Id);
        finder.setProductId(pro.Id);        
        finder.setOrderBy(SAPInvoicesFinderService.OrderByField.INV_DATE, SAPInvoicesFinderService.OrderByDirection.DESCENDING);
        finder.setMaxLines(10);
        Facturas_cabeceraSet__x[] results = finder.find();
        Map<String, List<Facturas_posicionesSet__x>> linesMap = finder.readItems();
        Test.stopTest();
        Assert.areEqual(0, results.size());
        Assert.areEqual(0, linesMap.keySet().size());
    }

    @isTest static void testFinder2() {
        Account acc = [select Id, SAP_Id__c from Account limit 1];
        if (acc.SAP_Id__c == null) {
            acc.SAP_Id__c = '123321';
            update acc;
        }
        Test.startTest();
        SAPInvoicesFinderService finder = new SAPInvoicesFinderService();
        finder.setSalesOrg('502');
        finder.setAccountId(acc.Id);
        finder.setOrderBy(SAPInvoicesFinderService.OrderByField.INV_DATE, SAPInvoicesFinderService.OrderByDirection.DESCENDING);

        finder.setAmountFilter(SAPInvoicesFinderService.AmountOptions.GREATER_THAN_ZERO);
        Facturas_cabeceraSet__x[] results = finder.find();

        finder.setAmountFilter(SAPInvoicesFinderService.AmountOptions.LESS_THAN_ZERO);
        results = finder.find();

        finder.setAmountFilter(SAPInvoicesFinderService.AmountOptions.EQUAL_TO_ZERO);
        results = finder.find();

        finder.setAmountFilter(SAPInvoicesFinderService.AmountOptions.NON_EQUAL_TO_ZERO);
        results = finder.find();

        Test.stopTest();
        Assert.areEqual(0, results.size());
    }



    @isTest static void testError1() {
        Account acc = [select Id, SAP_Id__c from Account limit 1];
        if (acc.SAP_Id__c != null) {
            acc.SAP_Id__c = null;
            update acc;
        }
        String error = null;
        Test.startTest();
        try {
            SAPInvoicesFinderService finder = new SAPInvoicesFinderService();
            finder.setAccountId(acc.Id);   
            finder.setOrderBy(SAPInvoicesFinderService.OrderByField.INV_DATE, SAPInvoicesFinderService.OrderByDirection.DESCENDING);
            finder.setMaxLines(10);        
            finder.find();
        } catch(Exception ex) {
            error = ex.getMessage();
        }
        Test.stopTest();
        Assert.isNotNull(error);
    }

    /*
    @isTest static void testError2() {
        Account acc = [select Id, SAP_Id__c from Account limit 1];
        if (acc.SAP_Id__c == null) {
            acc.SAP_Id__c = '123321';
            update acc;
        }
        Product2 pro = [select Id, StockKeepingUnit from Product2 limit 1];
        if (pro.StockKeepingUnit == null) {
            pro.StockKeepingUnit = '1000000';
            update pro;
        }
        String error = null;
        Test.startTest();
        SAPInvoicesFinderService finder = new SAPInvoicesFinderService();
        finder.setAccountId(acc.Id);
        finder.setProductId(pro.Id);    
        finder.setOrderNumber('555');
        finder.setOrderBy(SAPInvoicesFinderService.OrderByField.INV_DATE, SAPInvoicesFinderService.OrderByDirection.DESCENDING);
        finder.setMaxLines(10);
        List<    finder.find();
        Test.stopTest();
        Assert.isNotNull(error);
    }
        */

    @isTest static void testDummy() {
        Assert.isNotNull(SAPInvoicesFinderService.dummy());
    }

}