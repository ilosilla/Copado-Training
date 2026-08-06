/**
* @author 			Ramón Prades
* @date 			November-2020
* @group 			Accounts
* @description 	    Apex Controller for SAPDocs component (displays the list of sap docs of an account)
*/
public with sharing class SAPSalesDocumentController {

    /**
     * Gets header and items of a sales document (quote, order or invoice)
     */
    @AuraEnabled 
    public static SAPDocumentDTO getSAPDocument(String docType, String docNumber, Id accountId) {
        // AccountId is not used, but we pass null to the readDocument method because we can use the accountId for testing.
        SAPDocumentDTO doc = null;        
        switch on docType.toUpperCase() {
            when  'Q' {
                ExternalDataFetcher fetcher = new OfertasCabeceraDataFetcher();
                doc = readQuote(docNumber, fetcher, null);
            }
            when  'O' {
                ExternalDataFetcher fetcher = new PedidosCabeceraDataFetcher();
                doc = readOrder(docNumber, fetcher, null);
            }
            when  'I' {
                ExternalDataFetcher fetcher = new FacturasCabeceraDataFetcher();
                doc = readInvoice(docNumber, fetcher, null);
            }
        } // switch        
        return doc;
    } // getSAPDocument

    /**
     * Downloads the printout in pdf (a binary string) of a sales document
     */
    @AuraEnabled
    public static SAPWS_Utility.SapResponse downloadSAPDocument(String docType, String docNumber){
        try {
            /*if (docType.toLowerCase() == 'i') {
                docNumber = '6220100015';
            }*/
            String objectId = docType.toLowerCase() + '/' + docNumber.leftPad(10, '0');
            SAPWS_Utility.SapResponse response = SAPConnector.connect(objectId, SAPConnector.SALES_DOCUMENTS_SERVICE, 'GET', '');
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Downloads the printout in pdf (a binary string) of a sales document
     */
    @AuraEnabled
    public static String downloadSAPDocumentV2(String docType, String docNumber){
    //public static SAPWS_Utility.SapResponse downloadSAPDocument(String docType, String docNumber){ 
        try {
            Blob result = null;
            String objectId = docType.toLowerCase() + '/' + docNumber.leftPad(10, '0');
            SAPProxy proxy = new SAPProxy(SAPProxy.SALES_DOCUMENTS_SERVICE_V2);
            proxy.resourceId = objectId;
            proxy.method = 'GET';
            if (proxy.connectToSAP()) {
                return EncodingUtil.base64Encode(proxy.receivedBlob);
            } else {
                throw new AuraHandledException('Document not found');    
            }            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }

    /************************************************************************/

    @testVisible private static SAPDocumentDTO readQuote(String docNumber, ExternalDataFetcher fetcher, Id accountId) {
        
        SAPDocumentDTO dto = new SAPDocumentDTO();
        List<Ofertas_cabeceraSet__x> theList = fetcher.fetchData(docNumber);        
        if (theList.size()>0) {
            dto.docType = 'Q';
            dto.orderType = theList[0].Ordertype__c;
            dto.BillTo = theList[0].BillTo__c;
            dto.soldTo = theList[0].Customer__c;
            dto.docDate = theList[0].Orderdate__c.date();
            dto.docNumber = theList[0].Ordernum__c;
            dto.curr = theList[0].Dcurr__c;
            dto.net = theList[0].Dnet__c;                
            dto.tax = theList[0].Dtax__c;
            dto.total = theList[0].Dtotal__c;
            dto.lcurr = theList[0].Lcurr__c;
            dto.lnet = theList[0].Lnet__c;
            dto.ltax = theList[0].Ltax__c;
            dto.ltotal = theList[0].Ltotal__c;
            dto.status = (theList[0].OpenF__c);             
            dto.distChannel = theList[0].Distchannel__c;
            dto.salesOffice = theList[0].Salesoffic__c;
            dto.salesOrg = theList[0].Salesorg__c;
            dto.opportunity = theList[0].Sfopportunity__c;
            dto.reference = theList[0].Refer__c;
            dto.sapRep1 = theList[0].repo1__c;
            dto.sapRep2 = theList[0].repo2__c;
            // This is for testing only
            if (Test.isRunningTest()) {
                dto.accountId = accountId;
            }
            readQuoteItems(dto, fetcher.getItemsFetcher());
            fillDescriptions(dto);
        } 
        
        return dto;
    } // readQuote

    @testVisible private static SAPDocumentDTO readInvoice(String docNumber, ExternalDataFetcher fetcher, Id accountId) {
        
        SAPDocumentDTO dto = new SAPDocumentDTO();
        List<Facturas_cabeceraSet__x> theList = fetcher.fetchData(docNumber);        
        if (theList.size()>0) {
            dto.docType = 'I';
            dto.orderType = theList[0].Ordertype__c;
            dto.BillTo = theList[0].BillTo__c;
            dto.docDate = theList[0].Orderdate__c.date();
            dto.docNumber = theList[0].Ordernum__c;
            dto.curr = theList[0].Dcurr__c;
            dto.net = theList[0].Dnet__c;                
            dto.tax = theList[0].Dtax__c;
            dto.total = theList[0].Dtotal__c;
            dto.lcurr = theList[0].Lcurr__c;
            dto.lnet = theList[0].Lnet__c;
            dto.ltax = theList[0].Ltax__c;
            dto.ltotal = theList[0].Ltotal__c;
            if (theList[0].Paid__c == 'X') {
                dto.status = 'C';
            } else {
                dto.status = 'A';
            }
            dto.distChannel = theList[0].Distchannel__c;
            //dto.salesOffice = theList[0].Salesoffic__c;
            dto.salesOrg = theList[0].Salesorg__c;
            dto.opportunity = theList[0].Sfopportunity__c;
            dto.reference = theList[0].Refer__c;
            dto.sapRep1 = theList[0].repo1__c;
            dto.sapRep2 = theList[0].repo2__c;
            // This is for testing only
            if (Test.isRunningTest()) {
                dto.accountId = accountId;
            }            
            readInvoiceItems(dto, fetcher.getItemsFetcher());
            fillDescriptions(dto);
        } 
        
        return dto;
    } // readInvoice

    private static void readInvoiceItems(SAPDocumentDTO dto, ExternalDataFetcher fetcher) {
        dto.items = new List<SAPItemDTO>();
        list<Facturas_posicionesSet__x> lines = fetcher.fetchData(dto.docNumber);
        for (Facturas_posicionesSet__x line :lines ) {
            SAPItemDTO item = new SAPItemDTO();
            item.docNumber = line.orderNum__c;
            item.docLine = line.orderLin__c;
            item.SKU = line.SKU__c;
            item.name = line.name__c;
            item.quantity = line.quantity__c;
            item.unitCode = line.unitCode__c;
            item.curr = line.dcurr__c;
            item.net = line.dnet__c;
            item.tax = line.dtax__c;
            item.total = line.dtotal__c;            
            dto.items.add(item);
        }
    } // readInvoiceItems    

    private static void readQuoteItems(SAPDocumentDTO dto, ExternalDataFetcher fetcher) {
        dto.items = new List<SAPItemDTO>();
        list<Ofertas_posicionesSet__x> lines = fetcher.fetchData(dto.docNumber);
        for (Ofertas_posicionesSet__x line :lines ) {
            SAPItemDTO item = new SAPItemDTO();
            item.docNumber = line.orderNum__c;
            item.docLine = line.orderLin__c;
            item.SKU = line.SKU__c;
            item.name = line.name__c;
            item.quantity = line.quantity__c;
            item.unitCode = line.unitCode__c;
            item.curr = line.dcurr__c;
            item.net = line.dnet__c;
            item.tax = line.dtax__c;
            item.total = line.dtotal__c;            
            dto.items.add(item);
        }
    } // readQuoteItems    

    @testVisible private static SAPDocumentDTO readOrder(String docNumber, ExternalDataFetcher fetcher, Id accountId) {        
        SAPDocumentDTO dto = new SAPDocumentDTO();
        List<Pedidos_cabeceraSet__x> theList = fetcher.fetchData(docNumber);        
        if (theList.size()>0) {
            dto.docType = 'O';
            dto.orderType = theList[0].Ordertype__c;
            dto.BillTo = theList[0].BillTo__c;
            dto.soldTo = theList[0].Customer__c;
            dto.docDate = theList[0].Orderdate__c.date();
            dto.deliveryDate = theList[0].ddate__c.date();
            dto.docNumber = theList[0].Ordernum__c;
            dto.curr = theList[0].Dcurr__c;
            dto.net = theList[0].Dnet__c;                
            dto.tax = theList[0].Dtax__c;
            dto.total = theList[0].Dtotal__c;
            dto.lcurr = theList[0].Lcurr__c;
            dto.lnet = theList[0].Lnet__c;
            dto.ltax = theList[0].Ltax__c;
            dto.ltotal = theList[0].Ltotal__c;
            dto.status = (theList[0].OpenF__c);             
            dto.distChannel = theList[0].Distchannel__c;
            dto.salesOffice = theList[0].Salesoffic__c;
            dto.salesOrg = theList[0].Salesorg__c;
            dto.opportunity = theList[0].Sfopportunity__c;
            dto.reference = theList[0].Refer__c;
            dto.sapRep1 = theList[0].repo1__c;
            dto.sapRep2 = theList[0].repo2__c;
            // This is for testing only
            if (Test.isRunningTest()) {
                dto.accountId = accountId;
            }            
            readOrderItems(dto, fetcher.getItemsFetcher());
            fillDescriptions(dto);    
        }         
        return dto;
    } // readQuote

    private static void readOrderItems(SAPDocumentDTO dto, ExternalDataFetcher fetcher) {
        dto.items = new List<SAPItemDTO>();
        list<Pedidos_posicionesSet__x> lines = fetcher.fetchData(dto.docNumber);
        for (Pedidos_posicionesSet__x line :lines ) {
            SAPItemDTO item = new SAPItemDTO();
            item.docNumber = line.orderNum__c;
            item.docLine = line.orderLin__c;
            item.SKU = line.SKU__c;
            item.name = line.name__c;
            item.quantity = line.quantity__c;
            item.unitCode = line.unitCode__c;
            item.curr = line.dcurr__c;
            item.net = line.dnet__c;
            item.tax = line.dtax__c;
            item.total = line.dtotal__c;            
            dto.items.add(item);
        }
    } // readQuoteItems    


    private static void fillDescriptions(SAPDocumentDTO dto) {
       try {
            if (dto.accountId == null) {
                dto.accountId = AccountUtil.getFromSAPCode(dto.BillTo); 
            }
            setBillToProperties(dto);
            setSoldToProperties(dto);
            setStatusProperties(dto);
            dto.typeDescription = setTypeDescription(dto);
            dto.samples = SAPDocumentUtils.isSamplesDocument(dto.docType, dto.orderType, (Double) dto.net);
            dto.salesOrgName = OrganizationUtil.getSalesOrgName(dto.salesOrg);            
            dto.distChannelName = OrganizationUtil.getChannelName(dto.distChannel);                 
            dto.salesOfficeName = OrganizationUtil.getSalesOfficeName(dto.salesOffice);
            dto.opportunityName = OpportunityUtil.getName(dto.opportunity);      
            dto.rep1 = UserUtils.getSAPUserId(dto.sapRep1);
            dto.rep2 = UserUtils.getSAPUserId(dto.sapRep2);
            dto.rep1name = UserUtils.getUserName(dto.rep1);
            dto.rep2name = UserUtils.getUserName(dto.rep2);
        } catch (Exception ex) {}
    } // fillDescriptions

    private static String setTypeDescription(SAPDocumentDTO dto) {
        String description = '';
        switch on dto.docType {
            when 'Q' {
                description = Label.dict_quote;
            }
            when 'O' {
                if (dto.total < 0) {
                    description = Label.dict_creditOrder;
                } else {
                    description = Label.dict_order;
                }
            }

            when 'I' {
                if (dto.total < 0) {
                    description = Label.dict_creditNote;
                } else {
                    description = Label.dict_invoice;
                }
            }

        } 
        return description;
    }

    private static void setStatusProperties(SAPDocumentDTO dto) {
        switch on dto.status {
            when  'A' {
                dto.statusName = Label.saps_status_open;
                dto.statusIcon = 'utility:clock';
                dto.statusClass = 'slds-theme_success';
            }
            when  'B' {
                if (dto.docType == 'Q') {
                    dto.statusName = Label.saps_status_partConverted;
                } else {
                    dto.statusName = Label.saps_status_partInvoiced;
                }
                dto.statusIcon = 'utility:warning';
                dto.statusClass = 'slds-theme_warning';
            }
            when  'C' {
                if (dto.docType == 'Q') {
                    dto.statusName = Label.saps_status_converted;
                } else if (dto.docType == 'O') {
                    dto.statusName = Label.saps_status_invoiced;
                } else {
                    dto.statusName = label.saps_status_closed;
                }
                dto.statusIcon = 'utility:success';
                dto.statusClass = 'slds-theme_success';
            }
            when else {
                dto.statusName = Label.saps_status_unknown;
                dto.statusIcon = 'utility:question_mark';
                dto.statusClass = 'slds-theme_error';
            }
        }
    } // setStatusProperties

    private static void setBillToProperties(SAPDocumentDTO dto) {
        List<Account> accs = [select Id, isPersonAccount, name 
                                from Account 
                                where id = :dto.accountId];            
        if (accs.size() > 0) {
            dto.accountName = accs[0].Name;
            dto.isPersonAccount = accs[0].IsPersonAccount;
        }     
    } // getAccountProperties

    private static void setSoldToProperties(SAPDocumentDTO dto) {
        dto.soldToId = AccountUtil.getFromSAPCode(dto.soldTo);
        if (!String.isBlank(dto.soldToId)) {
            List<Account> accs = [select Id, isPersonAccount, name 
                                    from Account 
                                    where id = :dto.soldToId];            
            if (accs.size() > 0) {
                dto.soldToName = accs[0].Name;
                dto.soldToIsPersonAccount = accs[0].IsPersonAccount;
            }     
        }
    } // getAccountProperties

    public class SAPDocumentDTO {
        @AuraEnabled public String docType; 
        @AuraEnabled public String orderType;     
        @AuraEnabled public String typeDescription;             
        @AuraEnabled public Boolean samples;             
        @AuraEnabled public String BillTo; 
        @AuraEnabled public String soldTo;
        @AuraEnabled public String soldToId;
        @AuraEnabled public String soldToName;
        @AuraEnabled public Boolean soldToIsPersonAccount;
        @AuraEnabled public String reference;     
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Boolean isPersonAccount;
        @AuraEnabled public String salesOrg;        
        @AuraEnabled public String salesOrgName;    
        @AuraEnabled public String salesOffice;
        @AuraEnabled public String salesOfficeName;
        @AuraEnabled public String distChannel;
        @AuraEnabled public string distChannelName;
        @AuraEnabled public Date docDate;
        @AuraEnabled public Date deliveryDate;
        @AuraEnabled public String docNumber;
        @AuraEnabled public String curr;
        @AuraEnabled public Decimal net;
        @AuraEnabled public Decimal tax;
        @AuraEnabled public Decimal total;
        @AuraEnabled public String lcurr;
        @AuraEnabled public Double lnet = 0;
        @AuraEnabled public Double ltax = 0;
        @AuraEnabled public Double ltotal = 0;
        @AuraEnabled public Id opportunity;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String status;
        @AuraEnabled public String statusName;
        @AuraEnabled public String statusIcon;
        @AuraEnabled public String statusClass;
        @AuraEnabled public String sapRep1;
        @AuraEnabled public String rep1;
        @AuraEnabled public String rep1name;
        @AuraEnabled public String sapRep2;
        @AuraEnabled public String rep2;
        @AuraEnabled public String rep2name;
        @AuraEnabled public List<SAPItemDTO> items;
    } // inner class SAPHeaderDTO

    public class SAPItemDTO {
        @AuraEnabled public String docNumber;
        @AuraEnabled public String docLine;
        @AuraEnabled public String SKU;
        @AuraEnabled public String name;
        @AuraEnabled public Double quantity;
        @AuraEnabled public String unitCode;
        @AuraEnabled public String curr;
        @AuraEnabled public Double net;
        @AuraEnabled public Double tax;
        @AuraEnabled public Double total;
    }

    /*
    * Defines the interface that must be implemented by the external object reader.
    * This enables dependency injection, facilitating proper unit testing while
    * ensuring access to external objects is possible.
    */
    // Default implementation for real use
    public interface ExternalDataFetcher {
        ExternalDataFetcher getItemsFetcher();
        List<SObject> fetchData(String docNumber);        
    }

    // Data Fetcher for Ofertas_cabeceraSet__x
    public class OfertasCabeceraDataFetcher implements ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            return [SELECT 
                        BillTo__c, Customer__c, Dcurr__c, Ordertype__c, Orderdate__c, Ordernum__c, Dnet__c, Dtax__c,
                        Dtotal__c, Lcurr__c, Lnet__c, Ltax__c, Ltotal__c, OpenF__c,                
                        Distchannel__c, Salesoffic__c, Salesorg__c, Sfopportunity__c, Refer__c,
                        Repo1__c, Repo2__c
                    FROM Ofertas_cabeceraSet__x
                    WHERE Ordernum__c = :docNumber.leftPad(10, '0')];
        }

        public ExternalDataFetcher getItemsFetcher() {
            return new OfertasPosicionesDataFetcher();
        }
    }

    // Data Fetcher for Facturas_cabeceraSet__x
    public class FacturasCabeceraDataFetcher implements ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            return [SELECT 
                        BillTo__c, Dcurr__c, Orderdate__c, Ordertype__c, Ordernum__c, Dnet__c, Dtax__c,
                        Dtotal__c, Lcurr__c, Lnet__c, Ltax__c, Ltotal__c, OpenF__c, Paid__c,                
                        Distchannel__c, Salesorg__c, Sfopportunity__c, Salesoffic__c, Refer__c,
                        Repo1__c, Repo2__c
                    FROM Facturas_cabeceraSet__x
                    WHERE Ordernum__c = :docNumber.leftPad(10, '0')];
        }

        public ExternalDataFetcher getItemsFetcher() {
            return new FacturasPosicionesDataFetcher();
        }

    }

    // Data Fetcher for Pedidos_cabeceraSet__x
    public class PedidosCabeceraDataFetcher implements ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            return [SELECT 
                        BillTo__c, Customer__c, Dcurr__c, Ordertype__c, Orderdate__c, Ordernum__c, Dnet__c, Dtax__c,
                        Dtotal__c, Lcurr__c, Lnet__c, Ltax__c, Ltotal__c, OpenF__c, ddate__c,               
                        Distchannel__c, Salesoffic__c, Salesorg__c, Sfopportunity__c, Refer__c,
                        Repo1__c, Repo2__c
                    FROM Pedidos_cabeceraSet__x
                    WHERE Ordernum__c = :docNumber.leftPad(10, '0')];
        }

        public ExternalDataFetcher getItemsFetcher() {
            return new PedidosPosicionesDataFetcher();
        }

    }

    // Data Fetcher for Facturas_posicionesSet__x
    public class FacturasPosicionesDataFetcher implements ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            return [SELECT
                        orderNum__c, orderLin__c, SKU__c, name__c,
                        quantity__c, unitCode__c, dcurr__c, dnet__c, dtax__c, dtotal__c
                    FROM Facturas_posicionesSet__x
                    WHERE Ordernum__c = :docNumber.leftPad(10, '0')];
        }

        public ExternalDataFetcher getItemsFetcher() {
            return null;
        }

    }

    // Data Fetcher for Ofertas_posicionesSet__x
    public class OfertasPosicionesDataFetcher implements ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            return [SELECT
                        orderNum__c, orderLin__c, SKU__c, name__c,
                        quantity__c, unitCode__c, dcurr__c, dnet__c, dtax__c, dtotal__c
                    FROM Ofertas_posicionesSet__x
                    WHERE Ordernum__c = :docNumber.leftPad(10, '0')];
        }

        public ExternalDataFetcher getItemsFetcher() {
            return null;
        }

    }

    // Data Fetcher for Pedidos_posicionesSet__x
    public class PedidosPosicionesDataFetcher implements ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            return [SELECT
                        orderNum__c, orderLin__c, SKU__c, name__c,
                        quantity__c, unitCode__c, dcurr__c, dnet__c, dtax__c, dtotal__c
                    FROM Pedidos_posicionesSet__x
                    WHERE Ordernum__c = :docNumber.leftPad(10, '0')];
        }

        public ExternalDataFetcher getItemsFetcher() {
            return null;
        }

    }

}