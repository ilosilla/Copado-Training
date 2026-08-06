/**
* @author 		Ramón Prades
* @date 		August 2022
* @group 		Cases
* @description 	Controller class for SAP related cases
*/
public class SAPCasesController {

    /**
     * Saves a SAP Case     
     * "strItems" contains a JSON string with the list of items List<InvoiceLineDTO>.
     */
    @AuraEnabled public static Case saveSAPCase(Case sapCase, String strItems) {
        List<ProductListItem__c> listItems  = new List<ProductListItem__c>();
        if (String.isNotBlank(strItems)) {
            List<InvoiceLineDTO> items = (List<InvoiceLineDTO>) JSON.deserialize(strItems, List<InvoiceLineDTO>.class); 
            listItems = dtoToProductList(sapCase.SAPInvoice__c, items);      
        } 
        sapCase = SAPCasesService.saveSAPInvoiceCase(sapCase, listItems);
        return sapCase;
     }

     /**º
      *  Creates a credit note in SAP for a collection
      */
    @AuraEnabled public static SAPOrderDTO createSAPCollection(Id caseId) {   
        SAPCasesService.SAPCollectionDTO serviceDTO = SAPCasesService.createSAPCollection(caseId);
        SAPOrderDTO dto = new SAPOrderDTO();
        dto.orderNumber = serviceDTO.orderNumber;
        dto.restockingCharges = serviceDTO.restockingCharges;
        return dto;
    }

    /**
     * Reads some parameters needed in the LWC
     */    
    @AuraEnabled(cacheable=true) public static SAPCaseDTO readCaseParameters() {
        return new SAPCaseDTO();
    }

    /**
     * Requests approval
     */
    @AuraEnabled public static DateTime requestApproval(String caseId) {        
        return SAPCasesService.requestApproval(caseId);
    }

    /**
     * Approve a case
     */
    @AuraEnabled public static void approveCase(String caseId) {        
        SAPCasesService.approveCollection(caseId, UserInfo.getUserId()); // Same for claims and collectios
    }

    /**
     * Emails a claim to the factory
     */
    @AuraEnabled public static Case emailClaimToFactory(Case sapCase) {        
        sapCase.FactoryInquiryDate__c = System.today();
        SAPCasesService.saveSAPInvoiceCase(sapCase);
        SAPCasesMailerService.AsyncFactoryInquiryMail(sapCase.Id);
        return sapCase;
    }

    /* ----------------------- PRIVATE METHODS ----------------------- */

    private static List<ProductListItem__c> dtoToProductList(String SAPInvoice, List<InvoiceLineDTO> dtoItems) {
        List<ProductListItem__c> items = new List<ProductListItem__c>();
        for (InvoiceLineDTO dtoItem : dtoItems) {
            if (dtoItem.collected > 0) {
                ProductListItem__c item = new ProductListItem__c();
                item.Name__c = dtoItem.productName;
                item.ProductCode__c = dtoItem.productCode;
                item.Product__c = dtoItem.product2Id;
                item.Quantity__c = dtoItem.collected;
                item.Unit__c = dtoItem.unit;
                item.SAPDocument__c = 'INVOICE';
                item.SAPNumber__c = SAPInvoice;
                item.SAPLine__c = dtoItem.lineNo;
                items.add(item);
            }
        }
        return items;
    } // dtoToProductList

    /* ------------------------ INNER CLASSES ------------------------ */

    /* Data transfer objects */
    public class SAPCaseDTO {
        @AuraEnabled public String sapInvoiceRecordTypeId = RecordTypeLibrary.Case_SAPInvoice;
    }

    public class SAPOrderDTO {
        @AuraEnabled public String orderNumber;
        @AuraEnabled public Decimal restockingCharges = 0;
    }

    public class InvoiceLineDTO {
        @AuraEnabled public Boolean lineOK = false;
        @AuraEnabled public Integer lineNo;
        @AuraEnabled public String productCode;
        @AuraEnabled public String productName;
        @AuraEnabled public Double invoiced;
        @AuraEnabled public String unit;
        @AuraEnabled public String invString;
        @AuraEnabled public String colString;
        @AuraEnabled public Integer invBoxes;
        @AuraEnabled public Integer invPieces;   
        @AuraEnabled public Integer colBoxes = 0;
        @AuraEnabled public Integer colPieces = 0;   
        @AuraEnabled public Integer collected = 0;   
        @AuraEnabled public Boolean isTile = false;     
        @AuraEnabled public String product2Id;
        @AuraEnabled public Integer pcsxbox = 0;
    }


} // class