@IsTest(IsParallel=false) public with sharing class CaseClaimsControllerTest {

    @testSetup private static void makeData() {
        DataFactoryAccount.createBusinessAccounts(1);
        DataFactoryProduct.skipPriceBooks = true;
        DataFactoryProduct.createProducts();
    }

    @isTest private static void test() {
        CaseClaimsController.FetchDataDTO dto = CaseClaimsController.getAPIData();
        Assert.isNotNull(dto.fileUploadURL);
    }

    @isTest private static void testCreateClaims() {
        Test.startTest();
        String caseString = getCaseString();
        Case[] cases = CaseClaimsController.createClaimsFromString(caseString);
        Test.stopTest();
        Assert.areEqual(1, cases.size(), 'A case should have been created');
        CaseClaimsController.notifyNewClaims(new List<Id>{cases[0].Id});
    }

    @isTest private static void testGetInvoiceLines() {
        Test.startTest();
        Facturas_posicionesSet__x[] mockedLines = getMockedLines('4300');
        CaseClaimsController.setMockData(mockedLines);
        CaseClaimsController.LineDTO dto = CaseClaimsController.getInvoiceLine('4300', '1');
        Test.stopTest();
        
        Assert.isNotNull(dto, 'A result was expected');
    }

    private static Facturas_posicionesSet__x[] getMockedLines(String invoiceNumber) {
        Facturas_posicionesSet__x[] mockedLines = new List<Facturas_posicionesSet__x>();
        Integer lineNo = 0;
        for (Product2 prod : [select Id, ProductCode, Name, Umv__c from Product2]) {
            lineNo++;
            Decimal netAmount = lineNo * 100;            
            Decimal taxAmount = netAmount * 0.20;    
            Facturas_posicionesSet__x pos = new Facturas_posicionesSet__x(
                Ordernum__c = invoiceNumber,
                Orderlin__c = String.valueOf(lineNo),            
                Dnet__c = netAmount,
                Dtax__c = taxAmount,
                Dtotal__c = netAmount + taxAmount,
                Dcurr__c = 'USD',
                Sku__c = prod.ProductCode,
                Name__c = prod.Name,
                Quantity__c = lineNo
            );
            mockedLines.add(pos);
        }
        return mockedLines;
    }

    @isTest private static String getCaseString() {
        Account acc = [select Id from Account limit 1];
        return '[{"Invoice":"6215100036","Line":10,"AccountId":"' + acc.Id + '","AccountName":"ANTON BLACKSELL123","ProductId":"01t6900000C0cc5AAB","ProductCode":"100026606","ProductName":"FERROKER ALUMINIO    44X66(A)","Quantity":"15","SalesUnit":"PZS","Problem":"NOT-WORKING","Description":""}]';
    }
}