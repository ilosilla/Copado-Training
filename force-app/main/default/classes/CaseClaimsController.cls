/**
* @author 		Ramón Prades
* @date 		August 2022
* @group 		SAP
* @description 	Claims Controller
*/
public class CaseClaimsController {

    private static Facturas_posicionesSet__x[] mockedInvoiceLines = new List<Facturas_posicionesSet__x>();

    /**
     * Get the info necessary to access the file upload api
     */
    @AuraEnabled(Cacheable=true) public static FetchDataDTO getAPIData() {
        FetchDataDTO dto = new FetchDataDTO();
        dto.apiKey = EnterpriseSalesforceCatalog.SAP_IS_API_KEY;
        dto.fileUploadURL = EnterpriseSalesforceCatalog.FILE_UPLOAD_API;
        dto.claimRecordType = RecordTypeLibrary.Case_SAPClaim;
        dto.returnsRecordType = RecordTypeLibrary.Case_SAPInvoice;
        dto.unitsMap = PicklistCommons.getValues(Case.Unit__c);
        return dto;
    }    

    /**
     * Serialize parameters as String (otherwise they are read as undefined ??
     */
    @AuraEnabled public static Case[] createClaimsFromString(String claimsString) {
        ClaimProductDTO[] claims = (List<ClaimProductDTO>) JSON.deserialize(claimsString, List<ClaimProductDTO>.class);
        return createClaims(claims);
    }
    @AuraEnabled public static Case[] createClaims(ClaimProductDTO[] claims) { 
        SystemLog log = new SystemLog('CASES');
        log.setTag('CaseClaimsController');
        log.setSummary('Creating ' + claims.size() + ' claims');
        Case[] cases = new List<Case>();
        for (ClaimProductDTO claim : claims) {
            String invoiceLabel = System.Label.dict_invoice?.toUpperCase() ?? 'INVOICE'; 
            String claimLabel = System.Label.dict_claim?.toUpperCase() ?? 'CLAIM'; 
            String fullLabel = claimLabel + ' ' + invoiceLabel + ' ' + claim.Invoice + '-' + claim.Line;
            Case c = new Case();
            c.Subject = claim.AccountName + ' * ' + fullLabel;
            c.AccountId = claim.AccountId;
            c.SAPInvoice__c = claim.Invoice;
            c.SAPInvoiceLine__c = claim.Line;
            c.Description = claim.Description;
            c.RecordTypeId = RecordTypeLibrary.Case_SAPClaim;
            c.ProductId = claim.ProductId;
            c.ProductCode__c = claim.ProductCode;
            c.ProductName__c = claim.ProductName;
            c.Quantity__c = claim.Quantity;
            c.Unit__c = claim.SalesUnit;
            c.Problem__c = claim.Problem;
            c.Description = claim.Description;            
            cases.add(c);
        }
        try {
            log.setInputData(JSON.serializePretty(cases));
            log.addDebug('Creating ' + cases.size() + ' cases in CaseClaimsController.createClaims');
            SAPCasesService.createSAPInvoiceCase(cases);        
            log.addDebug('Looks like it has worked!');
            SystemLog.writeLog(JSON.serialize(log));
        } catch (Exception ex) {
            log.addError(ex);
            SystemLog.writeLog(JSON.serialize(log));
            throw new AuraHandledException(ex.getMessage());
        }
        return cases;
    }

    /**
     * Sends a mail to the owner
     */
    @AuraEnabled(cacheable=true) public static void notifyNewClaims(Id[] ids) {
        for (Id caseId : ids) {
            SAPCasesMailerService.AsyncNotifyNewClaim(caseId);
        }
    }

    /**
     * Returns the invoice lines
     */
    @AuraEnabled(cacheable=true) public static List<LineDTO> getInvoiceLines(String invoiceNumber) {
        List<LineDTO> lines = new List<LineDTO>(); 
        Facturas_posicionesSet__x[] positions;
        if (Test.isRunningTest() && mockedInvoiceLines?.size() > 0) {
            positions = mockedInvoiceLines;
        } else {
            positions = [select 
                Ordernum__c, Orderlin__c, Dnet__c, Dtax__c, Dtotal__c, Dcurr__c,
                Sku__c, Name__c, Quantity__c, Vrkme__c, Make__c
                from Facturas_posicionesSet__x
                where Ordernum__c = :invoiceNumber
                order by Orderlin__c ];
        }            
        for (Facturas_posicionesSet__x posi : positions) {
            LineDTO line = new LineDTO();
            line.Invoice = posi.Ordernum__c;
            line.Line =  Integer.valueOf(posi.Orderlin__c);
            line.Net =  posi.Dnet__c;
            line.Tax =  posi.Dtax__c;
            line.Total =  posi.Dtotal__c;
            line.Curr =  posi.Dcurr__c;
            line.ProductCode =  posi.Sku__c;
            line.ProductName =  posi.Name__c;
            line.Quantity =  posi.Quantity__c;
            line.SalesUnit =  posi.Vrkme__c;
            line.Make =  posi.Make__c;
            /*
            try {
                Product2 p = ProductUtils.getProduct(line.ProductCode);
                line.ProductId = p.Id;
            } catch(Exception ex) {
                line.ProductId = null;
            }
            */
            lines.add(line);
        }
        setProductIds(lines);
        return lines;
    }

    /**
     * Returns a invoice line
     */
    @AuraEnabled(cacheable=true) public static LineDTO getInvoiceLine(String invoiceNumber, String invoiceLine) {
        LineDTO line = new LineDTO();
        if (String.isNotBlank(invoiceNumber) && String.isNotEmpty(invoiceLine)) {
            Integer lineNumber = Integer.valueOf(invoiceLine);
            List<LineDTO> lines = getInvoiceLines(invoiceNumber);
            for (LineDTO dto :lines) {
                if (dto.Line == lineNumber) {
                    line = dto;
                    break;
                }
            }
        }
        return line;
    }

    @AuraEnabled public static void sendSolutionToCustomer(Id caseId, String email) {
        SAPCasesService.sendClaimSolutionToCustomer(caseId, email);
    }

    /**
     * Sets the product ID in the array of invoice lines
     */
    private static void setProductIds(LineDTO[] lines) {
        Set<String> codes = new Set<String>();
        for (LineDTO l : lines) {
            if (!codes.contains(l.ProductCode)) {
                codes.add(l.ProductCode);
            }
        }
        List<Product2> products = new ProductsSelector().selectByProductCode(codes);
        Map<String, Id> productMap = new Map<String, Id>();
        for (Product2 p2 : products) {
            if (!productMap.containsKey(p2.ProductCode)) {
                productMap.put(p2.ProductCode, p2.Id);
            }
        }
        for (LineDTO l : lines) {
            if (productMap.containsKey(l.ProductCode)) {
                l.ProductId = productMap.get(l.ProductCode);
            }
        }
    }

    @testVisible private static void setMockData(Facturas_posicionesSet__x[] posis) { 
        mockedInvoiceLines = posis;        
    }

    public class LineDTO {
        @AuraEnabled public String Invoice;
        @AuraEnabled public Integer Line;
        @AuraEnabled public Double Net;
        @AuraEnabled public Double Tax;
        @AuraEnabled public Double Total;
        @AuraEnabled public String Curr;
        @AuraEnabled public String ProductCode;
        @AuraEnabled public String ProductName;
        @AuraEnabled public Double Quantity;
        @AuraEnabled public String SalesUnit; 
        @AuraEnabled public String Make;
        @AuraEnabled public Id ProductId;        
    }

    public class ClaimDTO {
        @AuraEnabled public String Invoice;
        @AuraEnabled public Id AccountId;
        @AuraEnabled public String AccountName;
        @AuraEnabled public String Description;
    }

    public class ClaimProductDTO {
        @AuraEnabled public String Invoice {get; set;}
        @AuraEnabled public Integer Line {get; set;}
        @AuraEnabled public Id AccountId {get; set;}
        @AuraEnabled public String AccountName {get; set;}
        @AuraEnabled public String ProductId {get; set;}
        @AuraEnabled public String ProductName {get; set;}
        @AuraEnabled public String ProductCode {get; set;}
        @AuraEnabled public Double Quantity {get; set;}
        @AuraEnabled public String SalesUnit {get; set;}
        @AuraEnabled public String Problem {get; set;}
        @AuraEnabled public String Description {get; set;}
    }

    public class FileDTO {
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileContent;
    }

    public class FetchDataDTO {
        @AuraEnabled public String apiKey {get; set;}
        @AuraEnabled public String fileUploadURL {get; set;}
        @AuraEnabled public String claimRecordType {get; set;}
        @AuraEnabled public String returnsRecordType {get; set;}
        @AuraEnabled public Map<String, String> unitsMap {get; set;}
        @AuraEnabled public Integer policyDays {get; set;}
    }

}