/**
* @author 			Ramón Prades
* @date 			March 2021
* @group 			SAP
* @description 	    Controller for the SAP Status component
*/
public class SAPStatusController {

    @AuraEnabled 
    public static SAPStatusDTO getComponentData(String accountId, String salesOrg) {        
        SAPStatusDTO dto = new SAPStatusDTO();
        dto.enabled = (!SystemSettings.underDevelopment('SAP_Status') || userUtils.isTester() );
        if (dto.enabled) {
            List<Account> accounts = [select Id, SAP_Id__c from Account where id = :accountId];
            if (accounts.size() == 0) {
                throw new AuraHandledException('Customer not found!');
            }
            Account account = accounts[0];
            dto.sapId = account.SAP_Id__c;
            List<Sales_Org__c> orgs = getAccountOrgs(accountId);
            dto.salesOrgs = getComboOrgs(orgs);
             
            dto.documents = new List<SummaryItem>();
            if (salesOrg.length() > 0) {
                dto.defaultOrg = salesOrg;
            } else {
                dto.defaultOrg = getDefaultOrg(orgs);            
            }

            SummaryItem quotes = readQuoteData(accountId, dto.sapId, dto.defaultOrg);
            dto.documents.add(quotes);

            SummaryItem orders = readOrderData(accountId, dto.sapId, dto.defaultOrg);
            dto.documents.add(orders);

            SummaryItem invoices = readInvoiceData(accountId, dto.sapId, dto.defaultOrg);
            dto.documents.add(invoices);

            setCurrency(dto);
        }
        return dto;
    } // getComponentData

    @AuraEnabled 
    public static Map<String,Object> getSAPCreditData (String sapId, String salesOrg) {
        Map<String,Object> result = new Map<String,Object>();
        String oid = salesOrg + '?sap=' + sapId;
        SAPWS_Utility.SapResponse response = SAPConnector.connect(oid, SAPConnector.ZCLI_SERVICE, 'GET', '');  
        if (response.success) {
            result = (Map<String,Object>)JSON.deserializeUntyped(response.json); 
        } else {
            throw new AuraHandledException(response.message + ' (error code ' + response.code + ')');
        }
        return result;
    } // getSAPCredit 

    @AuraEnabled
    public static List<AgedOrdersDTO> getOrdersHistory(String sapId, String salesOrg) {
        String lblMonths = Label.dict_months;
        List<AgedOrdersDTO> result = new List <AgedOrdersDTO>();
        try {
            Date d2 = System.today();
            Date d1 = d2.addMonths(-3).addDays(1);
            AgedOrdersDTO dto = selectOrdersByDate(sapId, salesOrg, d1, d2);            
            dto.title = '0-3 ' + lblMonths;
            result.add(dto);

            d2 = System.today().addMonths(-3);
            d1 = d2.addMonths(-3).addDays(1);
            dto = selectOrdersByDate(sapId, salesOrg, d1, d2);
            dto.title = '3-6 ' + lblMonths;
            result.add(dto);

            d2 = System.today().addMonths(-6);
            d1 = d2.addMonths(-3).addDays(1);
            dto = selectOrdersByDate(sapId, salesOrg, d1, d2);
            dto.title = '6-9 ' + lblMonths;
            result.add(dto);

            d2 = System.today().addMonths(-9);
            d1 = d2.addMonths(-3).addDays(1);
            dto = selectOrdersByDate(sapId, salesOrg, d1, d2);
            dto.title = '9-12 ' + lblMonths;
            result.add(dto);

            dto = selectOrdersByDate(sapId, salesOrg, null, null);
            dto.title = Label.saps_allOrders;
            result.add(dto);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    } // getOrdersHistory

    private static AgedOrdersDTO selectOrdersByDate( String sapId, String salesOrg, Date dateFrom, Date dateTo) {
        AgedOrdersDTO dto = new AgedOrdersDTO();
        dto.dateFrom = dateFrom;
        dto.dateTo = dateTo;
        String soql = 'select orderdate__c, lcurr__c, lnet__c, ltax__c, ltotal__c from pedidos_cabeceraSet__x ' 
            + ' where billto__c = :sapId and Salesorg__c = :salesOrg';
        if (dateFrom != null && dateTo != null) {
            soql += ' and orderdate__c >= :dateFrom and orderdate__c <= :dateTo';
        }

        List<pedidos_cabeceraSet__x> orders = Database.Query(soql);
        for (pedidos_cabeceraSet__x order : orders) {
            dto.nDocuments++;
            dto.curr = order.lcurr__c;
            dto.net += order.lnet__c;
            dto.tax += order.ltax__c;
            dto.total += order.ltotal__c;
        }
        return dto;
    } // selectOrdersByDate

    
    private static SummaryItem readQuoteData(Id accountId, String sapId, String salesOrg) {
        String completed = 'C';
        SummaryItem item = new SummaryItem();
        item.lineNo = 10;
        item.docType = Label.saps_row_openQuotes;
        item.url = '/lightning/cmp/c__sapdocs?c__t=q&c__a=' + accountId + '&c__o=' + salesOrg;
        item.salesOrg = salesOrg;
        List<Ofertas_cabeceraSet__x> quotes = [select lcurr__c, lnet__c, ltax__c, ltotal__c, openf__c, ddate__c 
                                                from Ofertas_cabeceraSet__x 
                                                where BillTo__c = :sapId and Salesorg__c = :salesOrg and openF__c != :completed];
        for(Ofertas_cabeceraSet__x quote :quotes) {
            item.curr = quote.lcurr__c;
            item.net += quote.lnet__c;
            item.tax += quote.ltax__c;
            item.total += quote.ltotal__c;
            if (quote.ltotal__c <> 0) {
                item.count++;                    
            }
            if (quote.Ddate__c != null) {
                Date docDate = quote.Ddate__c.date();
                if (docDate > item.lastDoc) {
                    item.lastDoc = docDate;
                }
            }
        }
        if (item.count == 0) {
            item.lastDoc = null;
        }
        return item;
    } // readQuoteData
    
    private static SummaryItem readOrderData(Id accountId, String sapId, String salesOrg) {
        Double fnet = 0;
        Double ftax = 0;
        String completed = 'C';        
        SummaryItem item = new SummaryItem();
        item.lineNo = 20;
        item.docType = Label.saps_row_openOrders;
        item.url = '/lightning/cmp/c__sapdocs?c__t=o&c__a=' + accountId + '&c__o=' + salesOrg;
        item.salesOrg = salesOrg;
        List<Pedidos_cabeceraSet__x> orders = [select Ordernum__c, lcurr__c, lnet__c, ltax__c, ltotal__c, openf__c, ddate__c , BillTo__c, Salesorg__c
                        from Pedidos_cabeceraSet__x where BillTo__c = :sapId and Salesorg__c = :salesOrg and openF__c != :completed];
        for(Pedidos_cabeceraSet__x order :orders) {
            fnet = 0;
            ftax = 0;
            if (order.openf__c == 'B') {
                Map<String, Double> invoiced = SAPDocumentUtils.getInvoiced(order.Ordernum__c);
                fnet = invoiced.get('net');
                ftax = invoiced.get('tax');
            }
            item.curr = order.lcurr__c;
            item.net += order.lnet__c - fnet;
            item.tax += order.ltax__c - ftax;
            item.total += order.ltotal__c - (fnet + ftax);
            item.count++;                    
            if (order.Ddate__c != null) {
                Date docDate = order.Ddate__c.date();
                if (docDate > item.lastDoc) {
                    item.lastDoc = docDate;
                }
            }
        }
        if (item.count == 0) {
            item.lastDoc = null;
        }
        return item;
    } // readOrderData
    
    private static SummaryItem readInvoiceData(Id accountId, String sapId, String salesOrg) {
        SummaryItem item = new SummaryItem();
        item.lineNo = 30;
        item.url = '/lightning/cmp/c__sapdocs?c__t=i&c__a=' + accountId + '&c__o=' + salesOrg;        
        item.docType = Label.saps_row_openInvoices;
        item.salesOrg = salesOrg;
        List<Facturas_cabeceraSet__x> invoices = [select lcurr__c, lnet__c, ltax__c, ltotal__c, openf__c, ddate__c 
            from Facturas_cabeceraSet__x where BillTo__c = :sapId and Salesorg__c = :salesOrg and paid__c = ' '];
        for(Facturas_cabeceraSet__x invoice :invoices) {
            item.curr = invoice.lcurr__c;
            item.net += invoice.lnet__c;
            item.tax += invoice.ltax__c;
            item.total += invoice.ltotal__c;
            if (invoice.ltotal__c <> 0) {
                item.count++;                    
            }
            if (invoice.Ddate__c != null) {
                Date docDate = invoice.Ddate__c.date();
                if (docDate > item.lastDoc) {
                    item.lastDoc = docDate;
                }
            }
        }
        if (item.count == 0) {
            item.lastDoc = null;
        }
        return item;
    } // readOrderData

    private static void setCurrency(SAPStatusDTO dto) {
        for (SummaryItem item :dto.documents) {
            if (item.curr != null) {
                dto.curr = item.curr;
                break;
            }
        }
    } // setCurrency

    private static String getDefaultOrg(List<Sales_org__c> orgs) {
        String org = '';        
        if (!orgs.isEmpty()) {
            org = orgs[0].SalesOrg__c;  // first value is default value
            String userDefault = UserUtils.getDefaultSalesOrg();                        
            for(Sales_org__c oOrg :orgs) {
                if (oOrg.SalesOrg__c == userDefault) {
                    org = oOrg.SalesOrg__c;
                    break;
                }
            } // for
        }
        return org;
    } // getDetaultCompany
    
    private static List<Map<String, String>> getComboOrgs(List<Sales_org__c> orgs) {
        List<Map<String,String>> combo = new List<Map<String,String>>();
        for(Sales_Org__c org :orgs) {
            combo.add(new Map<String, String>{'value' => org.SalesOrg__c, 'label' => org.Name});
        }
        return combo;
    } // getComboOrgs
        
    private static List<Sales_Org__c> getAccountOrgs(String accountId) {
        List<Sales_org__c> orgs = new List<Sales_org__c>();
        List<AggregateResult> relations  = [select Sales_Org__c, count(Distribution_Channel__c) from Sales_Relationship__c where Account_Org__c = :accountId group by Sales_Org__c];        
        for (AggregateResult ar : relations)  {
            String org = (String) ar.get('Sales_Org__c');
            List<Sales_Org__c> aux = [select SalesOrg__c, Name, Company__c from Sales_Org__c where SalesOrg__c = :org];
            orgs.addAll(aux);
        }
        return orgs;
    } // getAcccountOrg

    public class SAPStatusDTO {
        @AuraEnabled public Boolean enabled;
        @AuraEnabled public String sapId;
        @AuraEnabled public String defaultOrg;
        @AuraEnabled public List<Map<String, String>> salesOrgs;
        @AuraEnabled public String curr;
        @AuraEnabled public List<SummaryItem> documents;
    }

    public class SummaryItem {
        @AuraEnabled public Integer lineNo;         
        @AuraEnabled public String docType;         // Quote/Order/Invoice^
        @AuraEnabled public String url;
        @AuraEnabled public String salesOrg;
        @AuraEnabled public String curr;         
        @AuraEnabled public Double net = 0;
        @AuraEnabled public Double tax = 0;
        @AuraEnabled public Double total = 0;
        @AuraEnabled public Integer count = 0;
        @AuraEnabled public Date lastDoc = Date.newInstance(2000, 1, 1);
    }

    public class SAPCreditDTO {
        @AuraEnabled public String sap_id;
        @AuraEnabled public String company;
        @AuraEnabled public String company_name;
        @AuraEnabled public Double balance_to_pay;
        @AuraEnabled public Double balance_to_refund;
        @AuraEnabled public String risk_category;
        @AuraEnabled public String risk_name;
        @AuraEnabled public Double credit_limit;
        @AuraEnabled public Double credit_insured;
        @AuraEnabled public Double risk_exposure;
        @AuraEnabled public Double credit_available;
        @AuraEnabled public String payment_terms;
        @AuraEnabled public String terms_name;
    }
    
    public class AgedOrdersDTO {
        @AuraEnabled public String title;
        @AuraEnabled public Date dateFrom;
        @AuraEnabled public Date dateTo;
        @AuraEnabled public Integer nDocuments = 0;
        @AuraEnabled public String curr;        
        @AuraEnabled public Double net = 0;
        @AuraEnabled public Double tax = 0;
        @AuraEnabled public Double total = 0;
    }




}