/**
 * 
 * B2BSalesDocContracts
 * Ramón, Feb 2026
 *
 * Purpose
 * -------
 * Defines the boundary DTOs (contracts) used by the B2B UI/API layer to exchange
 * Sales Document data (orders, invoices, etc.) with Lightning Web Components.
 *
 * Why this exists
 * --------------
 * - Core readers/selectors (SAP EO readers, SF selectors) should remain agnostic
 *   of the client technology and MUST NOT require @AuraEnabled annotations.
 * - LWC/Apex controllers need serializable DTOs. These contracts provide a
 *   stable, typed schema for that boundary without contaminating lower layers.
 *
 * Design notes
 * -----------
 * - DTOs are declared as inner classes to avoid “a million scattered classes”.
 * - Only simple, UI-friendly fields should live here (Strings, Id, Date/Datetime,
 *   Decimal, Lists). Avoid SObject references.
 * - Mapping from core DTOs to these contract DTOs happens in controllers (or
 *   a dedicated mapping layer), never inside the core readers.
 *
 * Usage
 * -----
 * - Apex controllers return these DTOs directly (or embed them in a wrapper
 *   detail/page DTO).
 * - LWC consumes these DTOs as the canonical UI contract.
 *
 * =========================================================
 */
public without sharing class B2BSalesDocContracts {


    /* =========================================================
     * SALES ORDERS
     * ========================================================= */
    public class OrderHeaderDTO {
        @AuraEnabled public String orderNumber { get; set; }          // Ordernum__c
        @AuraEnabled public Date orderDate { get; set; }              // Orderdate__c
        @AuraEnabled public Date deliveryDate { get; set; }           // Ddate__c
        @AuraEnabled public String status { get; set; }               // Status__c (10/11/12)
        @AuraEnabled public String poNumber { get; set; }             // Refer__c
        @AuraEnabled public Decimal net { get; set; }
        @AuraEnabled public Decimal tax { get; set; }
        @AuraEnabled public Decimal total { get; set; }               // Dtotal__c
        @AuraEnabled public String currencyCode { get; set; }         // Dcurr__c
        @AuraEnabled public String sapCustomerCode { get; set; }      // Customer__c
        @AuraEnabled public Id accountId { get; set; }                // AccountId (lookup a Account)
        @AuraEnabled public String salesOrg { get; set; }
        @AuraEnabled public String channel { get; set; }
        @AuraEnabled public String salesOffice { get; set; }
        @AuraEnabled public String sapShipToCode { get; set; }
        @AuraEnabled public String deliveryStatus { get; set; }
        @AuraEnabled public String invoiceStatus { get; set; }
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public Id contactPointAddressId { get; set; }
        @AuraEnabled public Id porcelanosaAddress { get; set; }
        @AuraEnabled public AddressDTO billingAddress { get; set; }
        @AuraEnabled public AddressDTO shippingAddress { get; set; }
        @AuraEnabled public List<OrderItemDTO> items { get; set; }
    }

    public class OrderItemDTO {
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public Integer lineNumber { get; set; }
        @AuraEnabled public String sku { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public String salesUnit { get; set; }
        @AuraEnabled public Decimal netUnitPrice { get; set; }
        @AuraEnabled public String netPriceUnit { get; set; }
        @AuraEnabled public Decimal netAmount { get; set; }
        @AuraEnabled public Decimal taxAmount { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public String currencyCode { get; set; }
        @AuraEnabled public Decimal squareMetres { get; set; }
        @AuraEnabled public String statusCode { get; set; }
        @AuraEnabled public String openFlag { get; set; }
        @AuraEnabled public Id productId { get; set; }
    }

}