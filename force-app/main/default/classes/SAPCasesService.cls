@SuppressWarnings('PMD.ExcessiveClassLength')
/**
* @author 		Ramón Prades
* @date 		January 2023
* @group 		Cases
* @description  Services to create cases related to a SAP document (mainly invoices)
*
* Translation Prefix: tr0005 (shared)
*
*/
public class SAPCasesService {

    public static final String TRANSPORT_EMAIL_KEY = 'COLLECTIONS';
    public static final String TRANSPORT_EMAIL_SUBKEY = 'TRANSPORT-';

    /**
     * Requests approval for a case
     */
    public static DateTime requestApproval(Id caseId) {        
        Case theCase = new CasesSelector().selectById(new Set<Id>{caseId})[0];
        if (theCase.isCollection__c) {
            if (theCase.Status != CasesDomain.STATUS_NEW) {
                throw new ContextException(System.Label.tr0005_301.replace('{0}', theCase.Status)); // This case does not need approval (status is {0})
            }
            ProductListItem__c[] items = new ProductListItemsSelector().selectByCase(new Set<Id>{theCase.Id});     
            // Change satus temporarily to simulate validation when the case is approved (to make sure the approval will succeed)
            String realStatus = theCase.Status;
            theCase.Status = CasesDomain.STATUS_APPROVED;
            validateSAPCase(theCase, items);           // Throws exception if errors
            theCase.Status = realStatus;
        }
        SAPCasesMailerService.AsyncRequestApproval(caseId);
        theCase.ApprovalRequested__c = DateTime.now();
        update theCase;
        return theCase.ApprovalRequested__c;
    }

    public static void sendClaimSolutionToCustomer(Id caseId, String email) {
        SAPCasesMailerService.AsyncSendClaimSolutionToCustomer(caseId, email);
        Case c = new Case();
        c.Id = caseId;
        c.Status = CasesDomain.CLAIM_STATUS_PROPOSAL;
        update c;
    }

    /**
     * Approves a case
     */
    public static void approveCollection(Id caseId, Id approver) {
        Case[] cases = new CasesSelector().selectById(new Set<Id>{caseId});
        if (cases.size() == 0) {
            throw new ObjectNotFoundException(System.Label.tr0005_302); // Case not found
        }
        Case c = Cases[0];
        if (!c.Approved__c) {
            c.Approved__c = true;
            c.ApprovedBy__c = approver;
            c.ApprovalDate__c = System.today();
            update c;
        }            
    } // 

    /**
     * Saves a SAP case
     */
    public static Case saveSAPInvoiceCase(Case sapCase) {   
        if (validateSAPCase(sapCase, null)) {
            setInvoiceData(new List<Case>{sapCase});     
            upsert sapCase;
        }
        return sapCase;
    }

    /**
     * Saves a SAP Invoice case (Collections)
     */
    public static Case saveSAPInvoiceCase(Case sapCase, ProductListItem__c[] items ) {           
        if (validateSAPCase(sapCase, items)) {
            setInvoiceData(new List<Case>{sapCase});     
            Boolean isNewRecord = (sapCase.Id == null);
            if (!isNewRecord && sapCase.IsCollection__c) {
                ProductListItem__c[] oldItems = [select Id from ProductListItem__c where Case__c = :sapCase.Id];
                delete oldItems;
            } 
            upsert sapCase;
            for (ProductListItem__c item : items) {
                item.Id = null;
                item.Case__c = sapCase.Id;
            }
            if (items.size() > 0) {
                insert items;
            }
            if (isNewRecord) {
                sapCase = new CasesSelector().selectById(new Set<Id>{sapCase.Id})[0];
            }
        }
        return sapCase;
    } // createCollection    

    /**
     * Creates a SAP Invoice case (Collections)
     */
    public static void createSAPInvoiceCase(Case[] sapCases) {   
        setInvoiceData(sapCases);
        upsert sapCases;        
    } // createCollection    

    /*
    // Este método sobra. Está para la subisa de US-624
    public static Case createSAPInvoiceCase(Case sapCase, List<ProductListItem__c> items) {
        return saveSAPInvoiceCase(sapCase, items);
    }
    */

    /**
     * Creates a collection order in SAP 
     */
    public static SAPCollectionDTO createSAPCollection(Id caseId) {
        
        Case theCase = new CasesSelector().selectById(new Set<Id>{caseId})[0];

        String warehouse = theCase.SAPWarehouse__c;
        if (String.IsBlank(warehouse)) {
            SAPCasesSettings__c settings = CasesDomain.getSAPSettings(theCase.SalesOrg__c, theCase.SAPInvoice__c);
            if (String.IsNotBlank(settings.COL_ReturnsWarehouse__c)) {
                String[] warehouses = settings?.COL_ReturnsWarehouse__c.split(';');
                warehouse = warehouses[0];
            }
        }
        ProductListItem__c[] items = new ProductListItemsSelector().selectByCase(new Set<Id>{theCase.Id});
        String sapId = AccountUtil.getSAPId(theCase.AccountId);
        //sapId = '1085217'; // TEST CUSTOMER SANDBOX ONLY
        SAPOrderCreator sapOrder = new SAPOrderCreator();
        if (theCase.ContactPointAddress__c != null) {
            ContactPointAddress cpa = [select SAPId__c from ContactPointAddress where Id = :theCase.ContactPointAddress__c limit 1];
            sapOrder.deliverTo = cpa.SAPId__c;
        }
        sapOrder.isCredit = true;
        sapOrder.sapCustomer = sapId;
        sapOrder.SAPInvoice = theCase.SAPInvoice__c;
        sapOrder.reference = theCase.SAPInvoice__c;
        sapOrder.orderReason = parseReason(theCase.Reason);
        sapOrder.deliveryDate = theCase.CollectionDate__c;
        sapOrder.applyRestockingFee = theCase.RestockFee__c;

        sapOrder.warehouse = warehouse;
        sapOrder.storePickup = theCase.CustomerReturns__c;
        for (ProductListitem__c item : items) {
            SAPOrderCreator.OrderItem orderItem = new SAPOrderCreator.OrderItem();
            orderItem.lineReference = Integer.valueOf(item.SAPLine__c);
            orderItem.productCode = item.ProductCode__c;
            orderItem.unitCode = item.Unit__c;
            orderItem.quantity = item.Quantity__c;
            sapOrder.items.add(orderItem);
        }

        sapOrder.create();
        if (!sapOrder.success) {
            throw new ValidationException(sapOrder.errorMessage);
        }
        theCase.SAPOrderNumber__c = sapOrder.orderNumber;
        Decimal restockingCharges = sapOrder.getRestockingCharges();
        if (theCase.Status == 'New' || theCase.status == 'Approved') {
            theCase.Status = 'Ready';
        }
        update theCase;
        SAPCollectionDTO dto = new SAPCollectionDTO();
        dto.orderNumber = sapOrder.orderNumber;
        dto.restockingCharges = restockingCharges;
        return dto;
    }

    /**
     * Updates the status from the info received from SAP
     */
    public static void updateStatusFromSAP(SAPDeliveryInfoDTO[] sapInfoList) {
        List<Case> casesForTransport = new List<Case>();
        for (SAPDeliveryInfoDTO dto : sapInfoList) {
            List<Case> cases = readCasesByOrderNumber(dto.orderNumber);
            for (Case c : cases) {
                c.SAPDeliveryNumber__c = dto.deliveryNumber;
                c.SAPDeliveryStatus__c = dto.status;
                Boolean updateConfirmed = (dto.action == 'GOODS-POSTED' || dto.action == 'GOODS-UNPOST');
                c.SAPGoodsPosted__c = dto.goodsPosted;
                if (updateConfirmed) {
                    if (c.SAPGoodsPosted__c) {
                        setGoodsReceived(c, dto.items);
                    } else {
                        resetGoodsReceived(c);
                    }
                }                
                if (dto.action == 'CREATE') {
                    casesForTransport.add(c);
                }
            }
            update cases;
        }
        SystemLog logger = new SystemLog('SAP-EVENTS');
        logger.setTag('COLLECTION-FOR-TRANSPORT');
        for (Case ct :casesForTransport) {
            try {
                logger.addInfo('Case for Transport ' + ct.SAPDeliveryNumber__c);
                Blob file = SAPSalesDocumentService.downloadSAPDocument('D', ct.SAPDeliveryNumber__c, 'ZE15');
                logger.addInfo('File downlaoded ' + (file != null) );
                SAPCasesMailerService.AsyncCollectionNoteCreated(ct.id, file);
                logger.addInfo('Mail sent');
            } catch (Exception ex) {
                logger.addError(ex);
            }
        }
        logger.saveLog();
    }

    /**
     * Sets the credit not number of a collection
     */
    public static void setSAPCreditNote(SAPCreditNoteDTO[] sapList) {
        List<Case> cases = new List<Case>();
        List<Case> invoicedCases = new List<Case>();
        for (SAPCreditNoteDTO dto : sapList) {
            if (dto.isCollection) {
                if (dto.action == 'CREATE') {
                    cases = readCasesByOrderNumber(dto.orderNumber);    
                } else if (dto.action == 'CLEAR'||dto.action == 'UNCLEAR') {
                    cases = readCasesByCreditNumber(dto.invoiceNumber);
                }
                for (Case c : cases) {                
                    switch on dto.action {
                        when 'CREATE' {
                            if (dto.isReversal) {
                                c.SAPCreditNote__c = null;
                            } else {
                                c.SAPCreditNote__c = dto.invoiceNumber;                                
                                invoicedCases.add(c);
                            }
                        }
                        when 'CLEAR' {
                            if (c.Status == CasesDomain.STATUS_INVOICED) {
                                c.Status = CasesDomain.STATUS_CLOSED;
                            }
                        }
                        /*
                        when 'UNCLEAR' {
                            // Desactivado también en el trigger Handler
                            if (c.Status == CasesDomain.STATUS_CLOSED) {
                                c.Status = CasesDomain.STATUS_INVOICED;
                            }
                        }*/
                    }
                }

                update cases;
            }
        }

        for (Case ci :invoicedCases) {
            Blob file = SAPSalesDocumentService.downloadSAPDocument('I', ci.SAPCreditNote__c);
            SAPCasesMailerService.AsyncAccountsEmail(ci.Id, file);
        }

    }

    /**
     * Creates a good will compensation order from a claim
     */
    public static Id createCompensationOrder(Id caseId) {
        CompensationOrderHelper helper = new CompensationOrderHelper(caseId);        
        Id orderId = helper.create();
        Case c = new Case();
        c.Id = caseId;
        c.CompensationOrderId__c = orderId;
        update c;
        return orderId;
    }

    /** 
     * Updates a case with the factory response
     */
    public static void updateCaseResponse(Case c, String response) {
        if (String.isBlank(response)) {
            return;
        }
        if (c.isClaim__c && String.isBlank(c.FactoryInquiryResponse__c) && c.FactoryInquiryDate__c != null) {
            if (response.length() > 200) {
                c.FactoryInquiryResponse__c = response.substring(0, 1000) + '[...]';
            } else {
                c.FactoryInquiryResponse__c = response;
            }
            update c;
        }
    }
    
    /* < < < < < < < < PRIVATE METHODS > > > > > > > > >  */

    @testVisible private static String parseReason(String reason) {
        if (String.isNotBlank(reason)) {
            return reason.substringBeforeLast('_');            
        } else {
            return '';
        }
    }

    /*
     * Complex validation that require access to items here. Simple validations
     * that depend on the case fields only are better in validation rules or in
     * the beforeInsert/beforeUpdate triggers in the CasesDomain class.
     */
    private static Boolean validateSAPCase(Case sapCase, ProductListItem__c[] items) {
        if (String.IsBlank(sapCase.SAPInvoice__c )) {
            throw new ValidationException(System.Label.tr0005_303); // SAP invoice number is required
        }
        // Claims
        if (sapCase.IsClaim__c) {
            if (sapCase.ProductId == null) {
                throw new ValidationException('Product is required');
            }
        } else {
            // Collections
            if (sapCase.IsCollection__c||sapCase.RecordTypeId == RecordTypeLibrary.Case_SAPInvoice) {
                if (sapCase.Status != CasesDomain.STATUS_NEW && sapCase.Status != CasesDomain.STATUS_REJECTED && items.size() == 0) {
                    throw new ValidationException(System.Label.tr0005_304); // Please select at least one item from the invoice
                }
            }
        }
        return true;
    } // Validate SAP Case

    private static Case[] readCasesByOrderNumber(String orderNumber) {
        String objectName = 'Case';        
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ', Account.Name,  Owner.Name FROM ' + objectName;
        query += ' WHERE SAPOrderNumber__c = \'' + orderNumber + '\'';
        List<Case> cases = Database.query(query);
        return cases;
    }

    private static Case[] readCasesByCreditNumber(String creditNumber) {
        String objectName = 'Case';        
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ', Account.Name,  Owner.Name FROM ' + objectName;
        query += ' WHERE SAPCreditNote__c = \'' + creditNumber + '\'';
        List<Case> cases = Database.query(query);
        return cases;
    }


    private static void setGoodsReceived(Case theCase, SAPDeliveryItemDTO[] items) {
        Boolean changed = false;
        ProductListItem__c[] caseItems = new ProductListItemsSelector().selectByCase(new Set<Id>{theCase.Id});
        for (ProductListItem__c caseItem : caseItems) {
            SAPDeliveryItemDTO dto = searchInDeliveryItems(caseItem.ProductCode__c, items);        
            if (dto != null) {                
                changed = true;
                caseItem.QuantityConfirmed__c = dto.quantity;
                caseItem.QuantityConfirmedUnit__c = dto.unit;
            }
        }
        if (changed) {
            update caseItems;
        }
    } // setGoodsReceived

    private static void resetGoodsReceived(Case theCase) {
        Boolean changed = false;
        ProductListItem__c[] caseItems = new ProductListItemsSelector().selectByCase(new Set<Id>{theCase.Id});
        for (ProductListItem__c caseItem : caseItems) {
            changed = true;
            caseItem.QuantityConfirmed__c = 0;
            caseItem.QuantityConfirmedUnit__c = '';
        }
        if (changed) {
            update caseItems;
        }
    } // resetGoodsReceived

    private static SAPDeliveryItemDTO searchInDeliveryItems(String productCode, SAPDeliveryItemDTO[] items) {
        SAPDeliveryItemDTO result = null;
        String pcode = productCode.replaceFirst( '^0+', '');
        for (SAPDeliveryItemDTO dto : items) {             
            String material = dto.material.replaceFirst( '^0+', '');
            if (material == pcode) {
                result = dto;
            }
        }
        return result;
    }

    /*
     * Sets fields from the sap invoce data
     */
    private static void setInvoiceData(List<Case> cases) {     
        Map<String, Facturas_cabeceraSet__x> sapInvoicesMap = new Map<String, Facturas_cabeceraSet__x>();   
        Map<String, Facturas_posicionesSet__x> sapItemsMap = new Map<String, Facturas_posicionesSet__x>();   
        Set<String> sapInvoiceNumbers = new Set<String>();
        for (Case c : cases) {
            if (c.SAPInvoice__c != null && !sapInvoiceNumbers.contains(c.SAPInvoice__c)) {
                sapInvoiceNumbers.add(c.SAPInvoice__c);                
            }
        }                 
        if (sapInvoiceNumbers.size() > 0) {            
            List<Facturas_cabeceraSet__x> facturas = new SAPInvoicesSelector().selectByNumber(sapInvoiceNumbers);                        
            for (Facturas_cabeceraSet__x invoice : facturas) {
                sapInvoicesMap.put(invoice.Ordernum__c, invoice);
            }
            List<Facturas_posicionesSet__x> items = new SAPInvoiceLinesSelector().selectByNumber(sapInvoiceNumbers);
            for (Facturas_posicionesSet__x item : items) {
                sapItemsMap.put(item.Ordernum__c, item);
            }
            for (Case c : cases) {
                if (c.SAPInvoice__c != null) {
                    Facturas_cabeceraSet__x factura = sapInvoicesMap.get(c.SAPInvoice__c);
                    if (factura != null) {
                        Facturas_posicionesSet__x item = sapItemsMap.get(c.SAPInvoice__c);
                        c.SalesOrg__c = factura?.Salesorg__c;
                        c.DistributionChannel__c = factura?.Distchannel__c;
                        c.CurrencyIsoCode = factura?.Lcurr__c;
                        c.Plant__c = item?.Werks__c;
                    }
                }
            }
        }
    }         
    public class SAPCollectionDTO {
        public String orderNumber;
        public Decimal restockingCharges = 0;
    }

    public class SAPCreditNoteDTO {
        public String invoiceNumber;
        public String orderNumber;
        public String deliveryNumber;
        public String refInvoiceNumber;
        public Boolean isCollection;
        public Boolean isReversal;
        public Boolean isCredit;
        public String salesOrg;
        public String channel;
        public String action;
    }

    public class SAPDeliveryInfoDTO {
        public String orderNumber;
        public String deliveryNumber;
        public String action;
        public String status;
        public Boolean goodsPosted;
        public List<SAPDeliveryItemDTO> items;
    }

    public class SAPDeliveryItemDTO {
        public String delivery;
        public Integer itemno;
        public String material;
        public Decimal quantity;
        public String unit;
        public String batch;
        public Decimal stk_quantity;
        public String stk_unit;        
        public Double stk_factor_num;
        public Double stk_factor_Den;
        public String order;
        public Integer orderitem;  
    }


} // class