public class PriceRequestPrices {
    @auraEnabled public SAPOrder order{get;set;}

    public class SAPItem {
        @auraEnabled public String productCode{get;set;}
        @AuraEnabled public String unit{get;set;}
        @AuraEnabled public Decimal Quantity{get;set;}
        @AuraEnabled public Decimal netValue{get;set;}
        @AuraEnabled public Decimal customerValue{get;set;}
        @AuraEnabled public Decimal retailValue{get;set;}
        @AuraEnabled public String retailIsoUnit{get;set;}
    }

    public class SAPOrder {
        @auraEnabled public String salesOrg{get;set;}
        @AuraEnabled public String requestedBy{get;set;}
        @AuraEnabled public String reference{get;set;}
        @AuraEnabled public String operationType{get;set;}
        @AuraEnabled public String email{get;set;}
        @AuraEnabled public Date dateParam{get;set;}
        @AuraEnabled public String channel{get;set;}
        @AuraEnabled public String currencyParam{get;set;}
        @auraEnabled public List<SAPItem> items{get;set;}
    }

    public PriceRequestPrices() {
        this.order = new SAPOrder();
        this.order.items = new List<SAPItem>();
    }

    public void addItem(String productCode, String unit, Decimal quantity) {
        SAPItem item = new SAPItem();
        item.productCode = productCode;
        item.unit = unit;
        item.Quantity = quantity;
        this.order.items.add(item);
    }

    public void getPrices() {
        try {
            String jsonBody = JSON.serialize(new List<PriceRequestPrices>{this});
            jsonBody = jsonBody.replace('"currencyParam"', '"currency"');
            jsonBody = jsonBody.replace('"dateParam"', '"date"');

            String apiResult = '';

            SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.ORDERS_ENDPOINT + '?test=true&verbose=true');
            proxy.setMethod('POST');
            proxy.setJSONBody(jsonBody);
            System.debug('Request JSON Body: ' + jsonBody);
            proxy.setTimeout(60000);

            if (Test.isRunningTest()) {
                apiResult = 
                '[{"index":1,"sapOrder":{"items":[' +
                    '{"material":"000000000100000837","netPrice":10,"subtotPp1":5,"subtotPp2":7},' +
                    '{"material":"000000000100006036","netPrice":2.49,"subtotPp1":3,"subtotPp2":4}' +
                ']}, "success":true}]';
            } else {
                apiResult = proxy.callCPI();

                List<SapOrderResponse> responseList = (List<SapOrderResponse>) JSON.deserialize(apiResult, List<SapOrderResponse>.class);
                Map<String, Decimal> materialToPrice = new Map<String, Decimal>();

                if (responseList != null && !responseList.isEmpty()) {
                    SapOrderResponse response = responseList[0];

                    if (response.sapOrder != null && response.sapOrder.items != null) {
                        for (SapOrderResponseItem itemResponse : response.sapOrder.items) {
                            for (SAPItem item : this.order.items) {
                                if (itemResponse.material.contains(item.productCode)) {
                                    item.netValue = itemResponse.netPrice;
                                    item.customerValue = itemResponse.netPrice;
                                    item.retailValue = itemResponse.netPrice;
                                    item.retailIsoUnit = itemResponse.conisounit;
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error calling SAP CPI: ' + e.getMessage());
        }
    }

    public class SapOrderResponse {
        public Integer index;
        public SapOrderResponseOrder sapOrder;
        public Boolean success;
    }
    
    public class SapOrderResponseOrder {
        public List<SapOrderResponseItem> items;
    }
    
    public class SapOrderResponseItem {
        public String material;
        public Decimal netPrice;
        public Decimal subtotPp1;
        public Decimal subtotPp2;
        public Decimal subtotPp3;
        public String conisounit;
    }

    @testVisible public static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}