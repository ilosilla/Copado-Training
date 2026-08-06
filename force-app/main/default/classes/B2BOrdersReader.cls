/**
 * B2BOrdersReader
 * Ramón Prades - February 2026
 *
 * Purpose
 * - Reads order from SAP and salesforce and returns results in a consolidated DTO.
 * - Used to populate the orders queries in the B2B storefront.
 * 
 * Design notes
 * - Keep the SOQL executer in a separate class to allow stubbing when testing
 * - The reader is intentionally "context-agnostic": it does NOT enforce user/account security checks.
 */
@SuppressWarnings('PMD.ExcessiveParameterList')
public without sharing class B2BOrdersReader {

    public static List<Pedidos_cabeceraSet__x> mockData;
    private static final String SAP_SELECT_FIELDS = 'Ordernum__c, Orderdate__c, Ddate__c, Refer__c, Dnet__c, Dtax__c, Dtotal__c, Dcurr__c, Customer__c, Salesorg__c, Distchannel__c, DestinoMerc__c, Status__c, OpenF__c, Account__c';
    public static final String DEV_CUSTOMER_CODE = '1087111'; // for testing in dev orgs without real SAP data
    public static final Boolean IS_DEV_MODE = true; // toggle hardcoded customer code override 

    /* =========================================================
     * PUBLIC DATA TRANSFER OBJECTS 
     * ========================================================= */
    public class OrderDTO {
        public String sapOrderNumber;    
        public String orderNumber;   
        public Id orderId;  
        public Date orderDate;    // Orderdate__c
        public Date deliveryDate; // Ddate__c
        public String poNumber;       // Refer__c
        public Decimal net;
        public Decimal tax;
        public Decimal total;         // Dtotal__c
        public String currencyCode;   // Dcurr__c
        public String SalesOrg;
        public String Channel;
        public String deliveryStatus;
        public String invoiceStatus;
        public String sapBillTo;
        public String sapShipToCode; 
        public String shipToName;
        public Id accountId;          // AccountId (lookup a Account)
        public String Origin;
    }

    /* =========================================================
     * PUBLIC METHODS - SELECT ALL OPEN ORDERS (SAP + SF)
     * ========================================================= */
    /**
    * Retrieves a list of open orders from SAP, including B2B orders
    * that have not yet been transferred into SAP.
    */
    public static List<OrderDTO> selectOpenOrders(Id accountId, String salesOrg, Integer maxOrders) {
        // First, get draft orders from salesforce
        List<OrderDTO> sfOrders = selectSFOpenOrders(accountId, salesOrg, maxOrders);
        maxOrders = maxOrders - sfOrders.size();
        if (maxOrders > 0) {
            // If we still have room, get open orders from SAP
            Account acc = [select SAP_Id__c from Account where Id = :accountId limit 1];
            String customerCode = acc.SAP_Id__c;        
            /*if (IS_DEV_MODE && SystemUtils.getOnSandbox())  {
                customerCode = DEV_CUSTOMER_CODE; // OVERRIDE FOR DEV TESTING ☠️☠️☠️
            }*/
            List<OrderDTO> sapOrders = selectSAPOpenOrders(customerCode, salesOrg, maxOrders);
            mapSAPOrdersWithSalesforce(sapOrders);
            sfOrders.addAll(sapOrders);
        }
        return sfOrders;
    }

    /**
    /* =========================================================
     * PUBLIC METHODS - SELECT FROM SAP
     * ========================================================= */
     public static List<OrderDTO> selectSAPOpenOrders(String customerCode, String salesOrg, Integer maxOrders) {
        return selectSAPOrders(customerCode, salesOrg, null, null, null, true, maxOrders);
    }

    public static List<OrderDTO> selectSAPOrders(String customerCode, String salesOrg, String period, Date fromDate, Date toDate, Boolean openOnly, Integer maxOrders) {
        SAPOrdersSelector selector = new SAPOrdersSelector();
        List<Pedidos_cabeceraSet__x> rows = selector.selectOrders(customerCode, salesOrg, period, fromDate, toDate, openOnly, maxOrders);
        if (Test.isRunningTest() && mockData != null) {
            rows = mockData;
        }
        
        List<OrderDTO> out = new List<OrderDTO>();
        for (Pedidos_cabeceraSet__x s : rows) {
            out.add(mapSAPRow(s));
        }
        return out;
    }

    /* =========================================================
     * PUBLIC METHODS - SELECT FROM SALESFORCE
     * ========================================================= */
    /**
     * Reads salesforce orders not optransferred to SAP.
     * Filters B2B orders only
     */
    public static List<OrderDTO> selectSFOpenOrders(String accountId, String salesOrg, Integer maxOrders) {
        Order[] orders = [
            SELECT 
                Id, OrderNumber, EffectiveDate, PoNumber, TotalAmount, TotalTaxAmount, GrandTotalAmount, CurrencyIsoCode,
                Account.SAP_Id__c, SalesOrg__c, Distribution_channel__c, Status, AccountId, Origin__c
            FROM Order
            WHERE Status = 'Draft' and AccountId = :accountId and SalesOrg__c = :salesOrg and Origin__c = 'B2B'
            ORDER BY EffectiveDate desc
        ];
        List<Id> orderIds = TypeConversionCommons.extractListOfIds(orders);
        OrderDeliveryGroup[] odgs = [select OrderId, DesiredDeliveryDate from OrderDeliveryGroup where OrderId in :orderIds];
        Map<String, SObject> mapOdg = TypeConversionCommons.listToMap(odgs, 'OrderId', false);
        List<OrderDTO> results = new List<OrderDTO>();
        for (Order o : orders) {
            OrderDTO mapped = mapSFRow(o); 
            OrderDeliveryGroup odg = (OrderDeliveryGroup) mapOdg.get(o.Id);
            if (odg != null) {
                mapped.deliveryDate = odg.DesiredDeliveryDate;
            }
            results.add(mapped);
        }
        return results;
    }

    /**
     * Retrieves sakesfoirce orders with the given sao order id
     */
    public static Map<String, SObject> selectOrdersBySAPId(Set<String> sapOrders) {
        Order[] orders = [SELECT Id, Sap_Id__c, OrderNumber, Origin__c FROM Order WHERE Sap_Id__c IN :sapOrders];
         return TypeConversionCommons.listToMap(orders, 'SAP_Id__c', false);
    }

   /* =========================================================
    * SAP ORDERS READER (FOR TESTS & STUBS)
    * ========================================================= */
    public class SAPOrdersSelector {   

        public List<Pedidos_cabeceraSet__x> selectOrders(String customerCode, String salesOrg, String period, Date fromDate, Date toDate, Boolean openOnly, Integer maxRecords) {
            List<String> w = new List<String>();
            w.add('Customer__c = \'' + String.escapeSingleQuotes(customerCode) + '\'');
            w.add('Salesorg__c = \'' + String.escapeSingleQuotes(salesOrg) + '\'');
            if (period != null && period != 'CUSTOM') {
                w.add('Orderdate__c = ' + period);
            }
            if (period == 'CUSTOM') {
                // Add custom date range filter
                w.add('Orderdate__c >= ' + formatDate(fromDate));
                w.add('Orderdate__c <= ' + formatDate(toDate));
            }
            // Only NOT fully invoiced
            if (openOnly) {
                w.add('OpenF__c != \'C\'');
            }
            String whereClause = String.join(w, ' AND ');
            String soql = 'SELECT ' + SAP_SELECT_FIELDS + ' FROM Pedidos_cabeceraSet__x WHERE ' + whereClause + ' ORDER BY Orderdate__c DESC ' + 'LIMIT ' + maxRecords;
            return Database.query(soql);
        }

        private String formatDate(Date d) {
            Datetime dt = Datetime.newInstanceGMT(d.year(), d.month(), d.day(), 0, 0, 0);
            return dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }
    } // Inner class



    /* =========================================================
     * PRIVATE METHODS
     * ========================================================= */
    @TestVisible private static OrderDTO mapSAPRow(Pedidos_cabeceraSet__x s) {
        OrderDTO dto = new OrderDTO();
        dto.sapOrderNumber = s.Ordernum__c;
        dto.orderDate = s.Orderdate__c?.date();
        dto.deliveryDate = s.Ddate__c?.date();
        dto.poNumber = s.Refer__c;
        dto.net = s.Dnet__c;
        dto.tax = s.Dtax__c;
        dto.total = s.Dtotal__c;
        dto.currencyCode = s.Dcurr__c;
        dto.SalesOrg = s.Salesorg__c;
        dto.Channel = s.Distchannel__c;
        dto.deliveryStatus = s.Status__c;
        dto.invoiceStatus = s.OpenF__c;
        dto.sapShipToCode = s.DestinoMerc__c;
        dto.accountId = s.Account__c;
        dto.sapBillTo = s.Customer__c;
        return dto; 
    }

    @TestVisible private static OrderDTO mapSFRow(Order o) {
        OrderDTO dto = new OrderDTO();
        dto.orderId = o.Id;
        dto.sapOrderNumber = '';
        dto.orderNumber = o.OrderNumber;
        dto.orderDate = o.EffectiveDate;
        dto.poNumber = o.PoNumber;
        dto.net = o.TotalAmount;
        dto.tax = o.TotalTaxAmount;
        dto.total = o.GrandTotalAmount;
        dto.currencyCode = o.CurrencyIsoCode;
        dto.SalesOrg = o.SalesOrg__c;
        dto.Channel = o.Distribution_channel__c;
        dto.accountId = o.AccountId;
        dto.sapBillTo = o.Account.SAP_Id__c;
        dto.deliveryStatus = '10'; // No SAP status, but we know it's not invoiced yet as it's in draft
        dto.Origin = o.Origin__c;
        return dto; 
    }

    /**
     * Maps a SAP Order with a Salesforce order number
     */
    public static void mapSAPOrdersWithSalesforce(List<OrderDTO> sapOrders) {

        // Build a set of SAP order numbers and query the related Salesforce Orders
        Set<String> sapOrderNumbers = new Set<String>();
        for (OrderDTO o : sapOrders) {            
            sapOrderNumbers.add(o.sapOrderNumber);           
        }

        // Read the related salesforce orders by sap order number
        Map<String, SObject> mappedOrders = B2BOrdersReader.selectOrdersBySAPId(sapOrderNumbers);
        for (OrderDTO o : sapOrders) {       
            if (mappedOrders.containsKey(o.sapOrderNumber)) {
                Order sfOrder = (Order)mappedOrders.get(o.sapOrderNumber);
                o.orderId = sfOrder.Id;
                o.orderNumber = sfOrder.OrderNumber;
                o.Origin = sfOrder.Origin__c;
            }
          }
   }        
}