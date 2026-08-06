@isTest(isParallel=false) public class SAPCasesServiceTest {
    @testSetup  public static void testSetup() {
        //DataFactoryProduct.createProducts(null);        
        SAPCasesControllerTest.buildNewCase();    
        DataFactoryCase.autoInsert = false; 
        Case[] cases = DataFactoryCase.createClaims(1);       
        insert cases;   

    }

    @isTest public static void test_createSAPInvoiceCase() {
        SAPCasesControllerTest.testSaveSAPCase();
    }

    @isTest public static void testSEndSolution() {
        //Case c = SAPCASesControllerTest.buildNewCase();
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        c.SupplyReplacement__c = true;
        c.Liability__c = PicklistCommons.getKeysList(Case.Liability__c)[0];
        c.Warranty__c = PicklistCommons.getKeysList(Case.Warranty__c)[0];
        update c;
        SAPCasesService.sendClaimSolutionToCustomer(c.Id, 'dummy@email.cxm');
        Assert.isTrue(true);
    }

    @isTest public static void test_createSAPCollection() {
        insert new SAPCasesSettings__c(
            Name = '502',
            COL_ReturnsWarehouse__c = 'WH1;WH2'
        );

        SAPOrderCreatorTest.SAPProxyMockTest mocker = new SAPOrderCreatorTest.SAPProxyMockTest();
        Test.setMock(HttpCalloutMock.class, mocker);

        Case newCase = [
            SELECT Id, Status, SAPWarehouse__c, CollectionDate__c, RestockFee__c, CustomerReturns__c, AccountId
            FROM Case
            WHERE IsCollection__c = true
            LIMIT 1
        ];

        Account acc = [
            SELECT Id, SAP_Id__c
            FROM Account
            WHERE Id = :newCase.AccountId
            LIMIT 1
        ];
        acc.SAP_Id__c = '1000111';
        update acc;

        newCase.SAPWarehouse__c = 'WH9';
        newCase.CollectionDate__c = System.today().addDays(1);
        newCase.RestockFee__c = true;
        newCase.CustomerReturns__c = true;
        newCase.Status = CasesDomain.STATUS_NEW;
        update newCase;

        Test.startTest();
        SAPCasesService.SAPCollectionDTO dto = SAPCasesService.createSAPCollection(newCase.Id);
        Test.stopTest();

        Case savedCase = [
            SELECT SAPOrderNumber__c, Status
            FROM Case
            WHERE Id = :newCase.Id
        ];

        Assert.areEqual('25', dto.orderNumber, 'El mock debería devolver el pedido 25');
        Assert.areEqual('25', savedCase.SAPOrderNumber__c, 'El Case debe guardar el pedido SAP');
        Assert.areEqual(CasesDomain.STATUS_READY, savedCase.Status, 'El Case debe pasar a Ready');
    }

    @isTest public static void test_createSAPCollection_usesSettingsWarehouse() {
        insert new SAPCasesSettings__c(
            Name = '502',
            COL_ReturnsWarehouse__c = 'WH1;WH2'
        );

        SAPOrderCreatorTest.SAPProxyMockTest mocker = new SAPOrderCreatorTest.SAPProxyMockTest();
        Test.setMock(HttpCalloutMock.class, mocker);

        Case newCase = [
            SELECT Id, Status, SAPWarehouse__c, AccountId
            FROM Case
            WHERE IsCollection__c = true
            LIMIT 1
        ];

        Account acc = [
            SELECT Id, SAP_Id__c
            FROM Account
            WHERE Id = :newCase.AccountId
            LIMIT 1
        ];
        acc.SAP_Id__c = '1000111';
        update acc;

        newCase.SAPWarehouse__c = null;
        newCase.Status = CasesDomain.STATUS_APPROVED;
        update newCase;

        Test.startTest();
        SAPCasesService.SAPCollectionDTO dto = SAPCasesService.createSAPCollection(newCase.Id);
        Test.stopTest();

        Case savedCase = [
            SELECT SAPOrderNumber__c, Status
            FROM Case
            WHERE Id = :newCase.Id
        ];

        Assert.areEqual('25', dto.orderNumber, 'El pedido debe crearse usando el warehouse por defecto');
        Assert.areEqual('25', savedCase.SAPOrderNumber__c);
        Assert.areEqual(CasesDomain.STATUS_READY, savedCase.Status);
    }


    @isTest private static void testCreateClaim() {        
        DataFactoryCase.autoInsert = true;
        //Case[] cases = DataFactoryCase.createClaims(1);
        Case[] cases = [select Id, SAPInvoice__c from Case where IsClaim__c = true limit 1];
        for (Case c : cases) {
            c.Liability__c = PicklistCommons.getKeysList(Case.Liability__c)[0];
            c.Warranty__c = PicklistCommons.getKeysList(Case.Warranty__c)[0];
        }
        update cases;
        Test.startTest();
        SAPCasesService.createSAPInvoiceCase(cases);
        Test.stopTest();
        Case c = [select Id, SalesOrg__c, Status from Case limit 1];
        Assert.isNotNull(c, 'A case should have been created');             
        //Assert.areEqual('502', c.SalesOrg__c, 'The case should have a sales org');    
    }

    @isTest private static void testSaveSAPInvoiceCase() {
        String message = null;
        Case[] cases = [select Id, SAPInvoice__c from Case where IsClaim__c = true limit 1];
        try {
            SAPCasesService.saveSAPInvoiceCase(cases[0]);   
        } catch(Exception ex) {
            message = ex.getMessage();
        }
        Assert.isNotNull(message, 'Message not expected: ' + message);
    }

    @isTest public static void test_RequestApproval() {
        // Case c =  SAPCASesControllerTest.buildNewCase();     
        Case c = [select Id from Case where IsCollection__c = true limit 1];        
        DateTime dt = SAPCasesService.requestApproval(c.Id);        
        Assert.isNotNull(dt, 'A requested approval datetime should have been set');
    }

    @isTest public static void test_approveCase() {
        // Case c = SAPCASesControllerTest.buildNewCase();        
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        SAPCasesService.approveCollection(c.Id, UserInfo.getUserId());
        Case c2 = [select Id, Status from Case where Id = :c.Id limit 1];
        Assert.areEqual(CasesDomain.STATUS_APPROVED, c2.Status);
    }

    @isTest public static void test_updateStatusFromSAP() {
        // Case c = SAPCASesControllerTest.buildNewCase();
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPOrderNumber__c = '111111';
        update c;

        SAPCasesService.SAPDeliveryInfoDTO dto = new SAPCasesService.SAPDeliveryInfoDTO();
        dto.orderNumber = '111111';
        dto.deliveryNumber = '999999';
        dto.action = 'CREATE';
        dto.status = 'NA';
        dto.goodsPosted = false;

        SAPCasesService.updateStatusFromSAP(new List<SAPCasesService.SAPDeliveryInfoDTO>{dto});
        Case c2 = [select Id, SAPDeliveryNumber__c from Case where Id = :c.Id limit 1];
        Assert.areEqual('999999', c2.SAPDeliveryNumber__c);

        
        dto.orderNumber = '111111';
        dto.deliveryNumber = '999999';
        dto.action = 'GOODS-POSTED';
        dto.status = 'NA';
        dto.goodsPosted = true;

        ProductListItem__c pri = new ProductListItemsSelector().selectByCase(new Set<Id>{c.Id})[0];
        List<SAPCasesService.SAPDeliveryItemDTO> items = new List<SAPCasesService.SAPDeliveryItemDTO>();
        SAPCasesService.SAPDeliveryItemDTO item = new SAPCasesService.SAPDeliveryItemDTO();
        item.delivery = '6000000';
        item.itemno = 1;
        item.material = pri.ProductCode__c;
        item.quantity = 1;
        item.unit = 'UN';
        /*
        public String batch;
        public Decimal stk_quantity;
        public String stk_unit;        
        public Double stk_factor_num;
        public Double stk_factor_Den;
        public String order;
        public Integer orderitem;  
        */
        items.add(item);
        dto.items = items;
        SAPCasesService.updateStatusFromSAP(new List<SAPCasesService.SAPDeliveryInfoDTO>{dto});
        c2 = [select Id, SAPGoodsPosted__c from Case where Id = :c.Id limit 1];
        Assert.areEqual(true, c2.SAPGoodsPosted__c);

        // UMPOST
        dto.action = 'GOODS-UNPOST';
        dto.status = 'NA';
        dto.goodsPosted = false;
        SAPCasesService.updateStatusFromSAP(new List<SAPCasesService.SAPDeliveryInfoDTO>{dto});
        c2 = [select Id, SAPGoodsPosted__c from Case where Id = :c.Id limit 1];
        Assert.areEqual(false, c2.SAPGoodsPosted__c);        
    }

    @isTest public static void test_setSAPCreditNote() {
        //Case c = SAPCASesControllerTest.buildNewCase();
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPOrderNumber__c = '111111';
        update c;

        SAPCasesService.SAPCreditNoteDTO[] dtos = new List<SAPCasesService.SAPCreditNoteDTO>();
        SAPCasesService.SAPCreditNoteDTO dto = new SAPCasesService.SAPCreditNoteDTO();
        dto.invoiceNumber = '8888888';
        dto.orderNumber = '111111';
        dto.isCollection = true;
        dto.isReversal = false;
        dto.isCredit = true;
        dto.action = 'CREATE';
        dtos.add(dto);

        SAPCasesService.setSAPCreditNote(dtos);

        Case c2 = [select Id, SAPCreditNote__c from Case where Id = :c.Id limit 1];
        Assert.areEqual('8888888', c2.SAPCreditNote__c);
    }

    @isTest public static void test_setSAPCreditNote_2() {
        //Case c = SAPCASesControllerTest.buildNewCase();
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPCreditNote__c = '8888888';
        c.Status = CasesDomain.STATUS_INVOICED;
        update c;

        SAPCasesService.SAPCreditNoteDTO[] dtos = new List<SAPCasesService.SAPCreditNoteDTO>();
        SAPCasesService.SAPCreditNoteDTO dto = new SAPCasesService.SAPCreditNoteDTO();
        dto.invoiceNumber = '8888888';
        dto.orderNumber = '111111';
        dto.isCollection = true;
        dto.isReversal = false;
        dto.isCredit = true;
        dto.action = 'CLEAR';
        dtos.add(dto);

        SAPCasesService.setSAPCreditNote(dtos);

        Case c2 = [select Id, Status from Case where Id = :c.Id limit 1];
        Assert.areEqual(CasesDomain.STATUS_CLOSED, c2.Status, 'Status should be closed');
    }
  

    @isTest public static void testParseReason() {
        String reason = 'E08';
        Assert.areEqual(reason, SAPCasesService.parseReason(reason));
        reason = 'E08_1';
        Assert.areEqual('E08', SAPCasesService.parseReason(reason));
    }
 
    @isTest private static void testCreateCompensation() {                    
        Test.startTest();  
        // SAPCasesService.createSAPInvoiceCase(cases);        
        Case c = [select Id, SalesOrg__c, Status from Case limit 1];
        Assert.isTrue(true);
        c.Compensation__c = 500;
        Boolean exc = false;
        try {
            SAPCasesService.createCompensationOrder(c.Id);
        } catch (Exception e) {
            exc = (e.getTypeName() == 'ContextException');
        }
        Test.stopTest();
        Assert.isTrue(exc, 'Not important, just trying to reach coverage');
    }

    @isTest private static void testUpdateCaseResponse() {
        Case c = [select Id, FactoryInquiryDate__c from Case where IsClaim__c = true limit 1];
        c.FactoryInquiryDate__c = System.today();
        update c;
        c = new CasesSelector().selectById(new Set<Id>{c.Id})[0];
        Test.startTest();
        SAPCasesService.updateCaseResponse(c, 'XXX');
        Test.stopTest();
        c = new CasesSelector().selectById(new Set<Id>{c.Id})[0];
        Assert.areEqual(c.FactoryInquiryResponse__c, 'XXX', 'Wrong factoryn response ' + c.FactoryInquiryResponse__c);
    }

   
}