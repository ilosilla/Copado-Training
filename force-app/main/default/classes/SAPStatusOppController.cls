/**
* @author 			Ramón Prades
* @date 			March-2021
* @group 			SAP
* @group-content 	../../ApexDocContent/SAP.htm
* @description 	    Controller for the Opportunity SAP Status component
*/
public class SAPStatusOppController {

    @TestVisible private static List<Ofertas_cabeceraSet__x> mockQuotes = new List<Ofertas_cabeceraSet__x>();
    @TestVisible private static List<Pedidos_cabeceraSet__x> mockOrders = new List<Pedidos_cabeceraSet__x>();
    @TestVisible private static List<Facturas_cabeceraSet__x> mockInvoices = new List<Facturas_cabeceraSet__x>();

    @AuraEnabled 
    public static ComponentDTO getComponentData(String oppId) {   
        ComponentDTO dto = new ComponentDTO();    
        dto.salesOrgs = new List<String>();
        dto.opportunityId = oppId;
        readQuotes(dto, oppId);
        readOrders(dto, oppId);
        readInvoices(dto, oppId);
        buildSalesOrgs(dto);
        return dto;
    } // getComponentData

    private static void readQuotes(ComponentDTO dto, String oppId) {
        Ofertas_cabeceraSet__x[] docs = selectQuotes(oppId);
        dto.quotesNet = 0;
        dto.quotesTax = 0;
        dto.quotesTotal = 0;
        dto.numQuotes = 0;
        dto.lastQuote = null;
        for (Ofertas_cabeceraSet__x doc : docs) {
            dto.numQuotes++;
            dto.curr = doc.Lcurr__c;
            dto.quotesNet += doc.Lnet__c;
            dto.quotesTax += doc.Ltax__c;
            if (dto.lastQuote == null || (dto.lastQuote <  doc.Orderdate__c.date())) {
                dto.lastQuote = doc.Orderdate__c.date();
            }
            dto.salesOrgs.add(doc.Salesorg__c);
        }
        dto.quotesTotal = dto.quotesNet + dto.quotesTax;
    } // readQuotes

    private static Ofertas_cabeceraSet__x[] selectQuotes(String oppId) {
        Ofertas_cabeceraSet__x[] docs = new List<Ofertas_cabeceraSet__x>();
        if(Test.isRunningTest()) {
            return mockQuotes;
        } else {
            return [
                select Ordernum__c, Orderdate__c, lcurr__c, lnet__c, ltax__c, Sfopportunity__c, openF__c, Salesorg__c
                from Ofertas_cabeceraSet__x 
                where Sfopportunity__c = :oppId and openF__c != 'C'
                ];
        }        
    } // selectQuotes
    
    private static void readOrders(ComponentDTO dto, String oppId) {
        Pedidos_cabeceraSet__x[] docs = selectOrders(oppId);
        dto.ordersNet = 0;
        dto.ordersTax = 0;
        dto.ordersTotal = 0;
        dto.numOrders = 0;
        dto.lastOrder = null;
        for (Pedidos_cabeceraSet__x doc : docs) {
            dto.numOrders++;
            Double fnet = 0;
            Double ftax = 0;
            if (doc.openf__c == 'B') {
                Map<String, Double> invoiced = SAPDocumentUtils.getInvoiced(doc.Ordernum__c);
                fnet = invoiced.get('net');
                ftax = invoiced.get('tax');
            }
            dto.curr = doc.Lcurr__c;
            dto.ordersNet += doc.Lnet__c - fnet;
            dto.ordersTax += doc.Ltax__c - ftax;
            if (dto.lastOrder == null || (dto.lastOrder <  doc.Orderdate__c.date())) {
                dto.lastOrder = doc.Orderdate__c.date();
            }
            dto.salesOrgs.add(doc.Salesorg__c);
        }
        dto.ordersTotal = dto.ordersNet + dto.ordersTax;
    } // readOrders

    private static Pedidos_cabeceraSet__x[] selectOrders(String oppId) {
        Pedidos_cabeceraSet__x[] docs = new List<Pedidos_cabeceraSet__x>();
        if(Test.isRunningTest()) {
            return mockOrders;
        } else {
            return [
                select Ordernum__c, Orderdate__c, lcurr__c, lnet__c, ltax__c, Sfopportunity__c, openF__c, Salesorg__c
                from Pedidos_cabeceraSet__x 
                where Sfopportunity__c = :oppId and openF__c != 'C'
                ];
        }        
    } // selectOrders

    private static void readInvoices(ComponentDTO dto, String oppId) {
        Facturas_cabeceraSet__x[] docs = selectInvoices(oppId);
        dto.invoicesNet = 0;
        dto.invoicesTax = 0;
        dto.invoicesTotal = 0;
        dto.numInvoices = 0;
        dto.lastInvoice = null;
        for (Facturas_cabeceraSet__x doc : docs) {
            dto.numInvoices++;
            dto.curr = doc.Lcurr__c;
            dto.invoicesNet += doc.Lnet__c;
            dto.invoicesTax += doc.Ltax__c;
            if (dto.lastInvoice == null || (dto.lastInvoice <  doc.Orderdate__c.date())) {
                dto.lastInvoice = doc.Orderdate__c.date();
            }
            dto.salesOrgs.add(doc.Salesorg__c);
        }
        dto.invoicesTotal = dto.invoicesNet + dto.invoicesTax;
    } // readInvoices

    private static Facturas_cabeceraSet__x[] selectInvoices(String oppId) {
        Facturas_cabeceraSet__x[] docs = new List<Facturas_cabeceraSet__x>();
        if(Test.isRunningTest()) {
            return mockInvoices;
        } else {
            return [
                select Ordernum__c, Orderdate__c, lcurr__c, lnet__c, ltax__c, Sfopportunity__c, openF__c, Salesorg__c
                from Facturas_cabeceraSet__x 
                where Sfopportunity__c = :oppId
                ];
        }        
    } // selectInvoices

    private static void buildSalesOrgs(ComponentDTO dto) {
        // remove dups
        List<String> uniqueOrgs = removeDuplicatedOrgs(dto);
        String userOrgs = [select Id, Sales_Org__c from User where Id =: UserInfo.getUserId() limit 1].Sales_Org__c;
        if (userOrgs == null) {
            userOrgs = ' ';
        }
        dto.salesOrgs = new List<String>();
        dto.permission = new List<Boolean>();     
        for(String orgCode :uniqueOrgs) {            
            List<Sales_Org__c> matchingOrgs = [select SalesOrg__c, Name from Sales_Org__c where SalesOrg__c = :orgCode];   
            String name = Label.dict_unknownSalesOrg;
            if (matchingOrgs.size() > 0) {
                name = matchingOrgs[0].Name;
            }
            dto.salesOrgs.add('[' + orgCode + '] ' + name);     
            if (userOrgs == null) {
                dto.permission.add(false);
            } else {
                dto.permission.add(userOrgs.contains(orgCode));
            }
        }
    }    

    private static List<String> removeDUplicatedOrgs(ComponentDTO dto) {
        Set<String> theSet = new Set<String>();
        theSet.addAll(dto.salesOrgs);
        List<String> result = new List<String>();
        result.addAll(theSet);
        return result;
    } // removeDupicatedOrgs

    public class ComponentDTO {
        @AuraEnabled public String curr;
        @AuraEnabled public List<String> salesOrgs;
        @AuraEnabled public List<Boolean> permission;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Double quotesNet;
        @AuraEnabled public Double quotesTax;
        @AuraEnabled public Double quotesTotal;
        @AuraEnabled public Integer numQuotes;
        @AuraEnabled public Date lastQuote;        
        
        @AuraEnabled public Double ordersNet;
        @AuraEnabled public Double ordersTax;
        @AuraEnabled public Double ordersTotal;
        @AuraEnabled public Integer numOrders;
        @AuraEnabled public Date lastOrder;

        @AuraEnabled public Double invoicesNet;
        @AuraEnabled public Double invoicesTax;
        @AuraEnabled public Double invoicesTotal;
        @AuraEnabled public Integer numInvoices;
        @AuraEnabled public Date lastInvoice;

    } // ComponentDTO
}