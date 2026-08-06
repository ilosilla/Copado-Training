/**
 * Clase para encapsular el acceso a pedidos SAP
 * Ramón Prades - February 2026
 *
 * Lee cabecera y líneas de SAP y devuelve los fresultados en un DTO consolidado
 * - 
 *
 * Design notes
 * - Los datos de SAP se leen de las tablas externas
 * - La idea es que esta clase devuelva el DTO con datos en vocabulario de negocio apra no tener que 
 *   lidiar con la estructura de las tablas externas en el resto del sistema
 */
public without sharing class SAPOrderReader {

    /* =========================================================
     * PUBLIC METHODS (API)
     * ========================================================= */

    public static B2BSalesDocContracts.OrderHeaderDTO readOrder(String sapId) {
        B2BSalesDocContracts.OrderHeaderDTO dto = SAPOrderReader.readHeader(sapId);
        if (dto != null) {
            dto.items = SAPOrderReader.readItems(sapId);
        }
        return dto;
    }

    public static B2BSalesDocContracts.OrderHeaderDTO  readHeader(String sapNumber) {
        B2BSalesDocContracts.OrderHeaderDTO header = null;
        Pedidos_cabeceraSet__x[] headers = [
            SELECT 
                Ordernum__c, Orderdate__c, Ddate__c, Status__c, Refer__c, Dnet__c, Dtax__c, Dtotal__c, Dcurr__c,
                Customer__c, Salesorg__c, Distchannel__c, Salesoffic__c, DestinoMerc__c
            FROM Pedidos_cabeceraSet__x
            WHERE Ordernum__c = :sapNumber            
        ];
        if (!headers.isEmpty()) {
            header = SAPOrderReader.mapHeader(headers[0]);
        }
        return header;
    }

    public static B2BSalesDocContracts.OrderItemDTO[] readItems(String sapNumber) {
        List<B2BSalesDocContracts.OrderItemDTO> lines = new List<B2BSalesDocContracts.OrderItemDTO>();
        Pedidos_posicionesSet__x[] items = [
            SELECT 
                Ordernum__c, Orderlin__c, Sku__c, Name__c, Quantity__c, Vrkme__c,
                Netpr__c, Kmein__c, Dcurr__c, Dnet__c, Dtax__c, Dtotal__c,
                Sqmetres__c, Status__c, OpenF__c
            FROM Pedidos_posicionesSet__x
            WHERE Ordernum__c = :sapNumber
            ORDER BY Orderlin__c
        ];
        for (Pedidos_posicionesSet__x item : items) {
            lines.add(SAPOrderReader.mapItem(item));
        }
        return lines;
    }

    /* =========================================================
     * PRIVATE METHODS
     * ========================================================= */

     @testVisible private static B2BSalesDocContracts.OrderHeaderDTO mapHeader(Pedidos_cabeceraSet__x header) {        
        B2BSalesDocContracts.OrderHeaderDTO  dto = new B2BSalesDocContracts.OrderHeaderDTO ();
        dto.orderNumber = header.Ordernum__c;
        dto.orderDate = header.Orderdate__c?.date();
        dto.deliveryDate = header.Ddate__c?.date();
        dto.status = header.Status__c;
        dto.poNumber = header.Refer__c;
        dto.net = header.Dnet__c;
        dto.tax = header.Dtax__c;
        dto.total = header.Dtotal__c;
        dto.currencyCode = header.Dcurr__c;
        dto.sapCustomerCode = header.Customer__c;
        dto.SalesOrg = header.Salesorg__c;
        dto.Channel = header.Distchannel__c;
        dto.SalesOffice = header.Salesoffic__c;
        dto.sapShipToCode = header.DestinoMerc__c;
        return dto;
    }

    @TestVisible private static B2BSalesDocContracts.OrderItemDTO  mapItem(Pedidos_posicionesSet__x item) {
        B2BSalesDocContracts.OrderItemDTO  dto = new B2BSalesDocContracts.OrderItemDTO ();
        dto.orderNumber = item.Ordernum__c;
        dto.lineNumber = Integer.valueOf(item.Orderlin__c ?? '0');
        dto.sku = item.Sku__c;
        dto.name = item.Name__c;
        dto.quantity = item.Quantity__c;
        dto.salesUnit = item.Vrkme__c;
        dto.netUnitPrice = item.Netpr__c;
        dto.netPriceUnit = item.Kmein__c;
        dto.currencyCode = item.Dcurr__c;
        dto.netAmount = item.Dnet__c;
        dto.taxAmount = item.Dtax__c;
        dto.totalAmount = item.Dtotal__c;
        dto.squareMetres = item.Sqmetres__c;
        dto.statusCode = item.Status__c;
        dto.openFlag = item.OpenF__c;
        return dto;
    }
}