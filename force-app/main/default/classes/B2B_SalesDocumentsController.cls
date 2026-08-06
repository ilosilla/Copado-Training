/**
 * =========================================================
 * B2B_SalesDocumentsController
 * =========================================================
 *
 * Purpose
 * -------
 * Controller for B2B Experience (LWC) to query sales documents.
 * V1: Open Orders (not fully invoiced) sourced from SAP External Objects and enriched with Salesforce Orders.
 *
 * Data sources
 * ------------
 * - SAP (External Object): Pedidos_cabeceraSet__x
 * - Salesforce: Order (enrichment by Order.Sap_Id__c)
 *
 * Testability
 * -----------
 * External Objects cannot be created in tests, so data access is isolated behind
 * top-level readers (B2B_SapOrdersReader, B2B_SfOrdersReader) that can be replaced with Test.createStub().
 *
 * =========================================================
 */
public without sharing class B2B_SalesDocumentsController {

    private enum PeriodPreset {
        THIS_MONTH,
        LAST_3_MONTHS,
        LAST_6_MONTHS,
        LAST_12_MONTHS,
        THIS_YEAR,
        LAST_YEAR,
        CUSTOM
    }

    public static final String DEV_CUSTOMER_CODE = '1087111'; // for testing in dev orgs without real SAP data
    public static final Boolean IS_DEV_MODE = true; // toggle hardcoded customer code override 

    // =========================================================
    // PUBLIC DATA TRANSFER OBJECTS
    // =========================================================
    public class OrderRowDTO {
        @AuraEnabled public String sapNumber;             // Our number (SAP)
        @AuraEnabled public String webOrderNumber;        // Salesforce OrderNumber when B2B (nullable)
        @AuraEnabled public Datetime orderDate;
        @AuraEnabled public Datetime deliveryDate;
        @AuraEnabled public String deliveryStatusCode;    // 10/11/12
        @AuraEnabled public String deliveryStatusLabel;
        @AuraEnabled public String poNumber;
        @AuraEnabled public Decimal total;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String entryChannel;               // B2B / Direct
        @AuraEnabled public String orderId;
        @AuraEnabled public String invoiceNumber;
    }

    public class OrderDetailDTO {
        @AuraEnabled public B2BSalesDocContracts.OrderHeaderDTO order;
        @AuraEnabled public String salesOrgName;
        @AuraEnabled public String billToName;
        @AuraEnabled public String billToAddress;
        @AuraEnabled public String shipToName;
        @AuraEnabled public String shipToAddress;
    }

    // =========================================================
    // PUBLIC API
    // =========================================================

    /**
     * Retrieves a list of open orders from SAP, including B2B orders
     * that have not yet been transferred into SAP.
     */
    @AuraEnabled(cacheable=true)
    public static OrderRowDTO[] getOpenOrders(Id accountId, Integer maxRecords) { 
        OrderRowDTO[] results = new OrderRowDTO[]{};
        
        // Get the sales org from the user
        User u = [select Id, Default_Sales_Organization__c from User where Id = :UserInfo.getUserId() limit 1];

        List<B2BOrdersReader.OrderDTO> orders = B2BOrdersReader.selectOpenOrders(accountId, u.Default_Sales_Organization__c, maxRecords);
        for (B2BOrdersReader.OrderDTO o : orders) {       
            OrderRowDTO row = mapToOrderRowDTO(o);            
            row.entryChannel = o.Origin == 'B2B' ? 'B2B' : 'DIRECT';
            // Eclude samples and returns
            if (o.total > 0) {
                results.add(row);
            }
        }        
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static OrderRowDTO[] getOrderHistory(Id accountId, String period, Integer maxRecords) {
        User u = [SELECT Default_Sales_Organization__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Account acc = [SELECT SAP_Id__c FROM Account WHERE Id = :accountId LIMIT 1];

        List<B2BOrdersReader.OrderDTO> orders = B2BOrdersReader.selectSAPOrders(
            acc.SAP_Id__c, u.Default_Sales_Organization__c, period, null, null, false, maxRecords
        );

        B2BOrdersReader.mapSAPOrdersWithSalesforce(orders);

        // Collect order numbers for invoice lookup
        Set<String> orderNumbers = new Set<String>();
        for (B2BOrdersReader.OrderDTO o : orders) {
            if (!String.isBlank(o.sapOrderNumber)) {
                orderNumbers.add(o.sapOrderNumber);
            }
        }

        // Map order number → first invoice found
        Map<String, String> invoiceByOrder = new Map<String, String>();
        if (!orderNumbers.isEmpty()) {
            for (Facturas_posicionesSet__x fp : [
                SELECT aubel__c, Ordernum__c
                FROM Facturas_posicionesSet__x
                WHERE aubel__c IN :orderNumbers
            ]) {
                String key = fp.aubel__c?.trim();
                if (!invoiceByOrder.containsKey(key)) {
                    invoiceByOrder.put(key, fp.Ordernum__c);
                }
            }
        }

        OrderRowDTO[] results = new OrderRowDTO[]{};
        for (B2BOrdersReader.OrderDTO o : orders) {
            if (o.invoiceStatus != 'C') {
                 continue;
            }
            OrderRowDTO row = mapToOrderRowDTO(o);
            row.entryChannel = o.Origin == 'B2B' ? 'B2B' : 'Direct';
            row.invoiceNumber = invoiceByOrder.get(o.sapOrderNumber);
            results.add(row);
        }
        return results;
    }

    /**
     * Get the details of a sales document. 
     * First tries from SAP and if not, from Salesforce.
     */
    @AuraEnabled(cacheable=true)
    public static OrderDetailDTO getOrderDetail(Id orderId, String sapId, Id accountId) {        
        OrderDetailDTO detailDTO = new OrderDetailDTO();
        // SAP gets priority
        if (!String.isBlank(sapId)) {
            detailDTO.order = SAPOrderReader.readOrder(sapId);
        }  else {
            detailDTO.order = SFOrderReader.readOrder(orderId);
        }
        if (detailDTO.order != null) {
            if (detailDTO.order.accountId == null) {
                detailDTO.order.accountId = accountId;
            }
            completeOrderDetail(detailDTO);
        }        
        return detailDTO;
    }

    // =========================================================
    // PRIVATE METHODS
    // =========================================================

    private static void completeOrderDetail(OrderDetailDTO dto) {
        dto.salesOrgName = OrganizationUtil.getSalesOrgName(dto.order.salesOrg);
        //to.order.accountId = accountId;
        if (dto.order.accountId != null && dto.order.billingAddress == null) {
            dto.order.billingAddress = AddressDTO.readFromAccount(dto.order.accountId);
        } 
        if (dto.order.billingAddress != null) {
            dto.billToName = dto.order.billingAddress.name;
        }
        AddressFormatter fmt = new AddressFormatter(dto.order.billingAddress).excludeCountryName();
        dto.billToAddress = String.join(fmt.format(), ' · ');
        if (dto.order.sapCustomerCode == dto.order.sapShipToCode) {
            dto.shipToName = dto.billToName;
            dto.shipToAddress = dto.billToAddress;
        } else if (dto.order.sapShipToCode != null) {
            ContactPointAddress[] cpas = new ContactPointAddressesSelector().selectBySapId(new Set<String>{dto.order.sapShipToCode});   
            if (!cpas.isEmpty()) {
                ContactPointAddress cpa = cpas[0];
                AddressDTO shipToAddress = AddressDTO.readContactPointAddress(cpa.Id);
                AddressFormatter shipToFmt = new AddressFormatter(shipToAddress).excludeCountryName();
                dto.shipToAddress = String.join(shipToFmt.format(), ' · ');
            }
        }
    }

    private static OrderRowDTO mapToOrderRowDTO(B2BOrdersReader.OrderDTO src) {
        if (src == null) {
            return null;
        }
        OrderRowDTO out = new OrderRowDTO();
        out.sapNumber = src.sapOrderNumber;
        out.webOrderNumber = src.orderNumber;
        out.orderDate = src.orderDate;
        out.deliveryDate = src.deliveryDate;
        out.deliveryStatusCode = src.deliveryStatus;
        out.deliveryStatusLabel = toDeliveryLabel(out.deliveryStatusCode);
        out.poNumber = src.poNumber;
        out.total = src.total;
        out.currencyCode = src.currencyCode;
        return out;
    }

    @SuppressWarnings('PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')   
    private static String toDeliveryLabel(String code) {
        if (code == '10') return 'Not delivered';
        if (code == '11') return 'In delivery';
        if (code == '12') return 'Delivered';
        return '—';
    }

}