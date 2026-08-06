/**
 * Clase para encapsular el acceso a pedidos Salesforce (Order / OrderItem / OrderDeliveryGroup)
 * Ramón Prades - February 2026
 *
 * Lee cabecera y líneas de Salesforce y devuelve los resultados en un DTO consolidado.
 *
 * Design notes
 * - Los datos se leen de objetos estándar (Order, OrderItem) y de entrega (OrderDeliveryGroup)
 * - La idea es devolver un DTO con vocabulario de negocio para evitar acoplar el resto del sistema
 *   a la estructura de Salesforce
 */
public without sharing class SFOrderReader {

    /* =========================================================
     * PUBLIC   DATA TRANSFER OBJECTS
     * ========================================================= */
    public class HeaderDTO {
        public Id orderId;
        public String orderNumber;          // Order.OrderNumber
        public Datetime orderDate;            // Order.EffectiveDate (Date) -> Datetime 00:00 (si lo prefieres Date, cambia tipo)
        public String orderStatus;
        public String poNumber;               // Order.PoNumber (si existe) o tu campo custom
        public Decimal net;
        public Decimal tax;    
        public Decimal total;                 // Order.TotalAmount (si aplica) o suma líneas
        public String currencyCode;           // Order.CurrencyIsoCode
        public Id accountId;                  // Order.AccountId
        public Id contactPointAddressId;      // delivery addr (si aplica)
        public Id porcelanosaAddressId;
        public AddressDTO billingAddress;
        public AddressDTO shippingAddress;
        public DeliveryDTO delivery;
        public List<ItemDTO> items = new List<ItemDTO>();
    }

    public class DeliveryDTO {
        public Id orderDeliveryGroupId;
        public String deliveryMethod;         // ejemplo: carrier / method
        public String trackingNumber;         // si existe (custom)
        public String deliveryStatus;         // si existe (custom)
        public AddressDTO shippingAddress;
    }    

    public class ItemDTO {
        public Id orderItemId;
        public Id orderId;
        public Integer lineNumber;
        public Id productId;
        public String sku;
        public String name;
        public Decimal quantity;
        public String salesUnit;
        public Decimal netUnitPrice;
        public String netPriceUnit;
        public Decimal netAmount;
        public Decimal taxAmount;
        public Decimal totalAmount;
        public String currencyCode;
        public Decimal squareMetres;        
    }

    /* =========================================================
     * PUBLIC METHODS (API)
     * ========================================================= */

    public static B2BSalesDocContracts.OrderHeaderDTO readOrder(Id orderId) {
        B2BSalesDocContracts.OrderHeaderDTO dto = SFOrderReader.readHeader(orderId);
        dto.items = SFOrderReader.readItems(orderId);
        return dto;
    }

    public static B2BSalesDocContracts.OrderHeaderDTO readHeader(Id orderId) {
        if (orderId == null) {
            throw new IllegalArgumentException('orderId is required.');
        }
        OrdersSelector selector = new OrdersSelector();
        selector.addRelationshipField('Account.SAP_Id__c');
        Order o = (Order) selector.selectSingle(orderId);

        OrderDeliveryGroup[] odgs = [
            select 
                Id, DeliverToName, DesiredDeliveryDate, DeliveryMethod__c, DeliverToStreet, DeliverToCity, DeliverToState, DeliverToStateCode,
                DeliverToPostalCode, DeliverToCountry, DeliverToCountryCode, 
                ContactPointAddress__c, PorcelanosaAddress__c, 
                PhoneNumber, EmailAddress, SAPId__c
            from OrderDeliveryGroup 
            where OrderId = :o.Id 
        ];

        B2BSalesDocContracts.OrderHeaderDTO dto = mapHeader(o);        
        dto.billingAddress = AddressDTO.readFromAccount(dto.accountId);

        if (odgs.size() > 0) {
            dto.deliveryDate = odgs[0].DesiredDeliveryDate;
            dto.shippingAddress = AddressDTO.readFromOrderDeliveryGroup(odgs[0]);
        }
        return dto;
    }

    public static List<B2BSalesDocContracts.OrderItemDTO> readItems(Id orderId) {
        List<B2BSalesDocContracts.OrderItemDTO> out = new List<B2BSalesDocContracts.OrderItemDTO>();

        List<OrderItem> items = [
            SELECT Id, OrderId, LineNumber, Product2Id, Product2.StockKeepingUnit, CustomName__c,
                   Quantity, SalesUnit__c, UnitPrice, UnitPriceUnitCode__c,
                   TotalLineAmount, TotalLineTaxAmount, TotalAmtWithTax, CurrencyIsoCode,
                   NB2B_SQMetres__c, NB2B_Delivery__c
            FROM OrderItem
            WHERE OrderId = :orderId
            ORDER BY LineNumber
        ];

        for (OrderItem i : items) {
            out.add(mapItem(i));
        }

        return out;
    }

    /* =========================================================
     * PRIVATE METHODS
     * ========================================================= */

    @TestVisible private static B2BSalesDocContracts.OrderHeaderDTO mapHeader(Order o) {
        B2BSalesDocContracts.OrderHeaderDTO dto = new B2BSalesDocContracts.OrderHeaderDTO();
        dto.orderNumber = o.OrderNumber;
        dto.orderDate = o.EffectiveDate;
        dto.poNumber = o.PoNumber;
        dto.net = o.TotalAmount;  
        dto.tax = o.TotalTaxAmount;
        dto.total = o.GrandTotalAmount;
        dto.currencyCode = o.CurrencyIsoCode;
        dto.sapCustomerCode = o.Account.SAP_Id__c ;
        dto.accountId = o.AccountId;
        dto.salesOrg = o.SalesOrg__c;
        dto.channel = o.Distribution_channel__c;
        dto.salesOffice = o.SalesOffice__c;
        dto.orderId = o.Id;
        return dto;
    }

    @TestVisible private static B2BSalesDocContracts.OrderItemDTO mapItem(OrderItem i) {
        B2BSalesDocContracts.OrderItemDTO dto = new B2BSalesDocContracts.OrderItemDTO();
        dto.lineNumber = i.LineNumber;
        
        dto.lineNumber = (i.LineNumber == null) ? null : Integer.valueOf(i.LineNumber);
        dto.productId = i.Product2Id;
        dto.sku = i.Product2.StockKeepingUnit;
        dto.name = String.isBlank(i.CustomName__c) ? null : i.CustomName__c;
        dto.quantity = i.Quantity;
        dto.salesUnit = i.SalesUnit__c;
        dto.netUnitPrice = i.UnitPrice;
        dto.netPriceUnit = i.UnitPriceUnitCode__c;

        dto.netAmount = i.TotalLineAmount;
        dto.taxAmount = i.TotalLineTaxAmount;
        dto.totalAmount = i.TotalAmtWithTax;
        dto.currencyCode = i.CurrencyIsoCode;
        dto.squareMetres = i.NB2B_SQMetres__c;

        return dto;
    }


}