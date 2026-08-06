/**
 * @author         Ramón Prades
 * @date           January 2026
 * @group          SAP
 * @description    Mapper responsible for transforming Salesforce Order data
 *                 into SAP Order DTOs. Designed to be reused both by
 *                 real order serialization and order simulation flows.
 *
 *                 This class does not access the database and does not
 *                 perform JSON serialization.
 */
public class SAPSalesOrderMapper {

    public static final String SAP_API_VERSION = '2.1';        

    // ------------------------------------------------------------
    // Input data (provided externally)
    // ------------------------------------------------------------
    private Order order;
    private OrderDeliveryGroup deliveryGroup;
    private List<OrderItem> items;

    // ------------------------------------------------------------
    // Behaviour flags
    // ------------------------------------------------------------
    private Boolean includePrices = true;
    private String emailAddress = '';
    private String requestedBy = null;

    // ------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------
    public SAPSalesOrderMapper(Order order, OrderDeliveryGroup deliveryGroup, List<OrderItem> items) {
        this.order = order;
        this.deliveryGroup = deliveryGroup;
        this.items = items;
    }

    // ------------------------------------------------------------
    // Configuration (fluent)
    // ------------------------------------------------------------

    /**
     * Excludes all price-related fields from the resulting SAP DTO.
     * Intended for order simulation scenarios.
     */
    public SAPSalesOrderMapper withoutPrices() {
        this.includePrices = false;
        return this;
    }

    /**
     * Defines an email to receive SAP's confirmation
     */
    public SAPSalesOrderMapper withConfirmationEmail(String email) {
        this.emailAddress = email;
        return this;
    }

    /**
     * Defines the SAP Sold-To account id explicitly.
     * Used when the Order has not been loaded from the database.
     */
    public SAPSalesOrderMapper withRequestedBy(String sapId) {
        this.requestedBy = sapId;
        return this;
    }

    // ------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------

    /**
     * Transforms the provided Salesforce Order data into a SAP
     * order header DTO.
     */
    public SAPOrderHeaderDTO transform() {
        
        SAPOrderHeaderDTO header = new SAPOrderHeaderDTO();        

        header.sourceOrderId = this.order.Id;
        header.OperationType = this.mapOrderType(this.order.Type);
        header.Version = SAP_API_VERSION;
        header.m_Date = this.order.EffectiveDate;        
        header.RequestedBy = this.requestedBy != null ? this.requestedBy : this.order.Account?.SAP_Id__c;
        header.Email = this.emailAddress;
        header.Reference = this.order.PONumber;

        header.DeliveryInstructions = this.deliveryGroup?.DeliveryInstructions;
        header.DeliverToAlias = '';
        header.DeliverTo = this.deliveryGroup?.SAPId__c;

        header.SalesOrg = this.fixRenamedOrgs(this.order.SalesOrg__c);
        header.Channel = this.order.Distribution_channel__c;
        header.Index = 0;

        header.DeliveryDate = this.deliveryGroup?.DesiredDeliveryDate;
        if (header.DeliveryDate == null) {
            header.DeliveryDate = this.order.DeliveryDate__c;
        }

        header.ApplyRestockingCharges = false;
        header.m_Currency = this.order.CurrencyIsoCode;
        header.invoice = this.order.ReferredInvoice__c;
        header.OrderReason = this.order.OrderReason__c ?? '';

        if (this.includePrices) {
            header.NetValue = this.order.TotalAmount;
            header.Total = this.order.GrandTotalAmount;
        }

        switch on this.order.NB2B_Delivery_Method__c {
                when '1' {
                    header.storePickup = true;
            }
            when '3' {
                header.shippingCondition = 'N6';
                header.freight = 'Z3';
            } 
            when 'N3' {
                header.shippingCondition = 'N3';
                header.freight = 'Z3';
            }
        }

        /*
        if (header.SalesOrg == null && this.order.SalesStoreId != null) {
            WebStore store = this.storesMap.get(this.order.SalesStoreId);
            header.SalesOrg = store?.SAPSalesOrg__c;
            header.Channel = store?.SAPChannel__c;
        }
        */

        header.Items = this.buildItems();
        return header;    
    }

    // ------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------

    /**
     * Builds the SAP order item DTO list.
     */
    private SAPOrderItemDTO[] buildItems() {

        SAPOrderItemDTO[] itemsDTO = new List<SAPOrderItemDTO>();

        for (OrderItem item: this.items) {
            SAPOrderItemDTO dto = new SAPOrderItemDTO();
            dto.Sequence = item.LineNumber;
            dto.ProductCode = item.StockKeepingUnit__c;
            dto.Unit = item.SalesUnit__c ??item.ProductSalesUnit__c;
            dto.Quantity = item.Quantity;
            dto.ProductName = item.ProductName__c;
            dto.SerialNumber = '';
            //dto.Shade;
            dto.lineRef = Integer.valueOf(item.ReferredLine__c);
            if (this.includePrices) {
                dto.PricePerUnit = item.ListPrice;
                dto.PriceUnit = dto.Unit;
                dto.NetValue = item.TotalLineAmount;
                dto.TaxAmount = item.TotalLineTaxAmount;
            }
            itemsDTO.add(dto);
        }        
        return itemsDTO;
    }


    /**
     * Maps salesforce order types to SAP API types
     */
    private String mapOrderType(String orderType) {
        String result = '';
        switch on orderType {                        
            when 'Z011'     { result = '30'; }      // Samples order
            when 'Z016'     { result = '12'; }      // Credit request
            when 'Z017'     { result = '22'; }      // Service order            
            when 'Z018'     { result = '10'; }      // Customer returns
            when 'Z018_F'   { result = '11'; }      // Free Customer returns
            when 'Z051'     { result = '31'; }      // Replacement order 
            when 'ZW04'     {                     // Material order
                result = this.includePrices ? '21' : '20';
            }
            when else {
                throw new ValidationException('Operation type not supported ' + orderType);
            }
        }
        return result;
    }

    /**
     * Fixes renamed sales orgs
     */
    @SuppressWarnings('PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
    private String fixRenamedOrgs(String org) {
        // Check for null to avoid NullPointerException
        if (org == null) {
            return null;
        }

        // Apply mapping if matches specific values
        if (org == '504') return '514';
        if (org == '505') return '515';
        if (org == '506') return '516';
        if (org == '507') return '517';
        if (org == '508') return '518';

        // Return unchanged for other values
        return org;
    }

    /*
     * This method was intented for sales stores linked to a sales org/channel
     * but finally not used.
     */
    /*
    private void readStores(Set<Id> storeIds) {
        this.storesMap = new Map<Id, WebStore>();        
        for (WebStore store  : [select Id, Name, SAPSalesOrg__c, SAPChannel__c from WebStore where id in :storeIds]) {
            this.storesMap.put(store.Id, store);
        }
    }
    */
}