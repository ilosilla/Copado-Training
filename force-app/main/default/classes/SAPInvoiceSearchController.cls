/**
 * @author         Ramón Prades
 * @date           January 2025
 * @layer          LWC Controllers
 * @description    description
*/
public class SAPInvoiceSearchController {

    @AuraEnabled public static SearchResultsDTO readInvoices(SearchDTO searchCriteria) {   
        SAPInvoicesFinderService finder = new SAPInvoicesFinderService();
        finder.setSalesOrg(searchCriteria.salesOrg);
        finder.setAccountId(searchCriteria.accountId);
        finder.setProductId(searchCriteria.productId);
        finder.setOrderNumber(searchCriteria.orderNumber);
        finder.setTimeframe(searchCriteria.timeframe);
        finder.setAmountFilter(SAPInvoicesFinderService.AmountOptions.GREATER_THAN_ZERO);        
        finder.setOrderBy(SAPInvoicesFinderService.OrderByField.INV_DATE, SAPInvoicesFinderService.OrderByDirection.DESCENDING);
        //finder.setMaxLines(5);

        SearchResultsDTO resultsDTO = new SearchResultsDTO();
        resultsDTO.invoices = finder.find();
        resultsDTO.invoiceLines = finder.readItems();
        resultsDTO.unitsMap = PicklistCommons.getValues(Product2.SalesUnit__c);
        return resultsDTO;
    }

    public class SearchDTO {
        @AuraEnabled public String salesOrg {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public String productId {get;set;}
        @AuraEnabled public String orderNumber {get;set;}
        @AuraEnabled public String timeframe {get;set;}
    }
    
    public class SearchResultsDTO {
        @AuraEnabled public List<Facturas_cabeceraSet__x> invoices;
        @AuraEnabled public Map<String, List<Facturas_posicionesSet__x>> invoiceLines;
        @AuraEnabled public Map<String, String> unitsMap;
    }

}