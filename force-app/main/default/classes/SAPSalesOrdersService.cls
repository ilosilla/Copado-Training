public without sharing class SAPSalesOrdersService {

    public static SAPOrderResultDTO readPricesFromSAP(SAPOrderHeaderDTO sapOrder) {
        String responseJSON = simulateOrderInSAP(sapOrder);
        return parseResponseFromSAP(responseJSON);
    }  
    
    /* ------------------------------ PRIVATE METHODS ------------------------------ */

    /**
     * Simulates the order in SAP and returns the raw JSON response
     */
    private static String simulateOrderInSAP(SAPOrderHeaderDTO header) {
        String response = '';
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.ORDERS_ENDPOINT);
        proxy.setMethod('POST');
        proxy.setQueryString('test=true&verbose=true');
        proxy.setJSONBody('[' + header.serialize() + ']');
        response = proxy.callCPI();
        return response;
    }

    /**
     * Parses the prices from the SAP response JSON
     */
    private static SAPOrderResultDTO parseResponseFromSAP(String responseJSON) {

        // Change currency field
        responseJSON = responseJSON.replace('"currency":', '"currencyCode":');
        SAPResponseDTO[] parsedOrders = (SAPResponseDTO[]) JSON.deserialize(responseJSON, SAPResponseDTO[].class);
        if (parsedOrders.isEmpty() || !parsedOrders[0].success) {
            throw new CalloutException('SAP order simulation failed. Response: ' + responseJSON);
        }
        SAPOrderDTO sapOrder = parsedOrders[0].sapOrder;

        SAPOrderResultDTO result = new SAPOrderResultDTO();
        result.lines = new List<SAPOrderLineDTO>();
        result.currencyCode = sapOrder.header.currencyCode;
        for (SAPResponseItemDTO sapItem : sapOrder.items) {
            SAPOrderLineDTO lineDTO = mapItemFromSAP(sapItem);
            result.lines.add(lineDTO);
            if (lineDTO.isShipping) {
                result.shippingNetAmount += lineDTO.netAmount;
                result.shippingTax += lineDTO.taxAmount;
            } else {
                result.goodsNetAmount += lineDTO.netAmount;
                result.goodsTax += lineDTO.taxAmount;
            }
        }
        result.totalAmount = result.goodsNetAmount + result.goodsTax + result.shippingNetAmount + result.shippingTax;        
        return result;
    }

    /**
     * Maps a single item from SAP response to SAPOrderLineDTO
     */
    private static SAPOrderLineDTO mapItemFromSAP(SAPResponseItemDTO item) {
        
        SAPOrderLineDTO line = new SAPOrderLineDTO();        
        line.lineNo = item.itmNumber;
        line.stockKeepingUnit = item.material;
        line.name = item.shortText;
        line.quantity = item.reqQty ?? 0;
        line.quantityUnit = item.salesUnit;
        line.netPrice = item.netPrice ?? 0;
        line.netPriceUnit = item.condUnit;
        Decimal unitsInPrice = item.condPUnt ?? 1;
        line.netPrice = line.netPrice / unitsInPrice;
        line.netAmount = item.netValue ?? 0;
        line.taxAmount = item.taxAmount ?? 0;
        line.totalAmount = line.netAmount + line.taxAmount;
        line.isShipping = line.stockKeepingUnit.containsIgnoreCase('FLETE');

        line.stockKeepingUnit = stripLeadingZeros(line.stockKeepingUnit);
        line.quantityUnit = UnitConversionCommons.sapUnitToSalesforce(line.quantityUnit);
        line.netPriceUnit = UnitConversionCommons.sapUnitToSalesforce(line.netPriceUnit);

        return line;
    }

    private static String stripLeadingZeros(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.replaceFirst('^0+', '');
    }

    /* ------------------------------ DTO CLASSES ------------------------------ */

    public class SAPOrderResultDTO {
        public Decimal goodsNetAmount = 0;
        public Decimal goodsTax = 0;
        public Decimal shippingNetAmount = 0;
        public Decimal shippingTax = 0;
        public Decimal totalAmount = 0;
        public String currencyCode;
        public List<SAPOrderLineDTO> lines;
    }

    public class SAPOrderLineDTO {
        public Integer lineNo;
        public String stockKeepingUnit;
        public String name;
        public Decimal quantity;
        public String quantityUnit;
        public Decimal netPrice = 0;
        public String netPriceUnit;
        public Decimal netAmount = 0;
        public Decimal taxAmount = 0;
        public Decimal totalAmount = 0;
        public Boolean isShipping = false;
    }

    private class SAPResponseDTO {
        private Integer index;
        private Boolean success;
        private SAPOrderDTO sapOrder;
    }

    private class SAPOrderDTO {
        private SAPResponseHeaderDTO header;
        private List<SAPResponseItemDTO> items;
    }

    private class SAPResponseHeaderDTO {
        private String docType;
        private Decimal netValHd;
        private String currencyCode;
        private String salesOrg;
        private String distrChan;
        private String purchNo;
        public String soldTo;
    }

    private class SAPResponseItemDTO {
        // --- Identificación
        private Integer itmNumber;
        private String material;
        private String shortText;

        // --- Cantidades
        private Decimal reqQty;
        private String salesUnit;

        // --- Precios
        private Decimal netPrice;
        private String condUnit;
        private Decimal condPUnt;

        // --- Importes
        private Decimal netValue;
        private Decimal taxAmount;
    }

    private class ParsedSAPOrder {
        Map<String, Object> header;
        List<Object> items;
    }

}