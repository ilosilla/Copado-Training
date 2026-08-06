/**
 * @author         Ramón Prades
 * @date           January 2025
 * @layer          LWC Controller
 * @description    Controller class to read SAP documents for libSAPDocumentsQuery component
*/
public class SAPDocumentsQueryController {

    @AuraEnabled(cacheable=true) public static Facturas_cabeceraSet__x readInvoice(String invoiceNumber) {
        return new SAPInvoicesSelector().selectByNumber(invoiceNumber);        
    }

    @AuraEnabled(cacheable=true) public static ResultDTO readInvoiceWithDetails(String invoiceNumber) {
        ResultDTO dto = new ResultDTO();
        dto.sapInvoice = new SAPInvoicesSelector().selectByNumber(invoiceNumber);      
        if (checkPermission(dto?.sapInvoice)) {
            dto.sapItems = new SAPInvoiceLinesSelector().selectByNumber(invoiceNumber);
            dto.AccountName = AccountUtil.getName(dto.sapInvoice.Account__c );
            dto.SalesOrgName = OrganizationUtil.getSalesOrgName(dto.sapInvoice.Salesorg__c);
            //dto.productIds = searchProductIds(dto.sapItems);
            dto.productMap = buildProductMap(dto.sapItems);
            dto.settings = CasesDomain.getSAPSettings(dto.sapInvoice.Salesorg__c, dto.sapInvoice.Ordernum__c);
            dto.readyForCase = isInvoiceReadyForCase(dto.sapInvoice.Ordertype__c);
        } else {
            throw new SecurityException('Insufficient permissions to access this invoice (sales organization is ' + dto.sapInvoice.Salesorg__c + ')');
        }
        return dto;
    }

    public class ResultDTO {
        @AuraEnabled public Facturas_cabeceraSet__x sapInvoice {get; set;}
        @AUraEnabled public Facturas_posicionesSet__x[] sapItems {get; set;}
        @AuraEnabled public String accountName {get; set;}
        @AuraEnabled public String salesOrgName {get; set;}        
        @AuraEnabled public Map<String, Product2> productMap {get; set;}
        @AuraEnabled public SAPCasesSettings__c settings {get; set;}
        @AuraEnabled public Boolean readyForCase {get; set;}

    }

    //======================================================================================================

    private static Boolean checkPermission(Facturas_cabeceraSet__x invoice) {
        return UserCommons.hasAccessToSalesOrg(UserInfo.getUserId(), invoice.Salesorg__c);
    }

    private static Map<String, Product2>  buildProductMap(Facturas_posicionesSet__x[] items) {
        Map<String, Product2> productMap = new Map<String, Product2>();
        List<String> codes = TypeConversionCommons.extractFieldValues(items, 'Sku__c');
        if (codes.size() > 0) {
            List<Product2> products = [select Id, StockKeepingUnit, BoxXPal__c from Product2 where StockKeepingUnit in :codes];
            for  (Product2 product :products) {
                productMap.put(product.StockKeepingUnit, product);
            }
        }
        return productMap;
    }

    private static Boolean isInvoiceReadyForCase(String invoiceType) {
        // Only certain order types are eligible for case creation
        return (invoiceType == 'Z001' || invoiceType == 'Z004' || invoiceType == 'Z005' || invoiceType == 'Z006' || invoiceType == 'Z007');
    }

}