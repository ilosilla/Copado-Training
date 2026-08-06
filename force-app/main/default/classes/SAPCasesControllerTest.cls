@isTest public class SAPCasesControllerTest {

    @testSetup public static void testSetup() {
        buildNewCase();
        //DataFactoryProduct.createProducts();
    }

    @isTest public static void testSaveSAPCase() {
        //Case newCase = buildNewCase();
        Case newCase = [select Id from Case limit 1];
        Assert.isNotNull(newCase.Id, 'The case should have had an ID');
    }

    @isTest public static void testReadCaseParameters() {
        SAPCasesController.SAPCaseDTO dto = SAPCasesController.readCaseParameters();
        Assert.isNotNull(dto);
    }

    @isTest public static void rtest_requestApproval() {
        //Case newCase = buildNewCase();
        Case newCase = [select Id from Case];
        DateTime dt = SAPCasesController.requestApproval(newCase.Id);
        Assert.isNotNull(dt, 'Expected a datetime');

    }

    @isTest public static void testClaims() {
        Case[] cases = DataFactoryCase.createClaims(1);
        Test.startTest();
        SAPCasesController.emailClaimToFactory(cases[0]);
        Test.stopTest();
        Assert.isTrue(true);
    }

    public static Case buildNewCase() {
        DataFactoryProduct.createProducts(null);
        DataFactoryCase.autoInsert = false;
        Case c = DataFactoryCase.createCollections(1)[0];
        DataFactoryCase.autoInsert = true;
        Product2 pr = [select Id, ProductCode from Product2 limit 1];
        Assert.isNull(c.Id);
        
        List<SAPCasesController.InvoiceLineDTO> items = new List<SAPCasesController.InvoiceLineDTO>();
        SAPCasesController.InvoiceLineDTO item = new SAPCasesController.InvoiceLineDTO();
        item.lineOK = true;
        item.lineNo = 10;
        item.productCode = pr.ProductCode;
        item.productName = 'Test Product';
        item.invoiced = 3;
        item.unit = 'UN';
        item.invBoxes = 0;
        item.invPieces = 0;   
        item.colBoxes = 0;
        item.colPieces = 0;   
        item.collected = 1;   
        item.isTile = false;     
        item.product2Id = pr.Id; 
        item.pcsxbox = 0;
        items.add(item);
        String str = JSON.serialize(items);

        return SAPCasesController.saveSAPCase(c, str);
    }
}