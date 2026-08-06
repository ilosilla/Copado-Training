/**
* @author 		Ivan Losilla
* @date 		November 2025
* @group 		Price Requests
* @description 	Helper para el Price Request de filiales
* @test 	PriceRequestHelperTest
*/
public class PriceRequestHelper {

    public PriceRequestHelper() {
        // Constructor vacío
    }

    /*public static Map<String, Decimal> getProductPrices(String sapId, String org, String channel, String office,String curency, List<PricebookEntry> productItems) {
            String apiResult = null;
            Map<String, Decimal> result = new Map<String, Decimal>();

            String jsonBody = JSON.serialize(new List<OrderWrapper>{listToWrapper(sapId,org,channel,office,curency,productItems)},true);
            jsonBody = jsonBody.replace('"currencyIsoCode"', '"currency"');
            jsonBody = jsonBody.replace('"dateParam"', '"date"');

            SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.ORDERS_ENDPOINT + '?test=true&verbose=true');

            proxy.setMethod('POST');
            proxy.setJSONBody(jsonBody);
            System.debug('Request JSON Body: ' + jsonBody);
            proxy.setTimeout(60000);

            if (Test.isRunningTest()) {
                apiResult = 
                '[{"index":1,"sapOrder":{"items":[' +
                    '{"material":"000000000100000837","netPrice":10},' +
                    '{"material":"000000000100006036","netPrice":2.49}' +
                ']}, "success":true}]';

                result = new Map<String, Decimal>{'000000000100000837' => 10, '000000000100006036' => 2.49};
            } else {
                apiResult = proxy.callCPI();
                result = getMaterialNetPrices(apiResult);
            }
            
            return result;
    }


    private static OrderWrapper listToWrapper(String sapId, String org, String channel, String office,String curency, List<PricebookEntry> productItems) {
        OrderWrapper wrapper = new OrderWrapper();
        wrapper.order = new OrderHeader();
        wrapper.order.operationType = '20';
        wrapper.order.dateParam = System.today();
        wrapper.order.reference = 'TEST ORDER';
        wrapper.order.requestedBy = sapId;
        wrapper.order.salesOrg = org;
        wrapper.order.channel = channel;
        wrapper.order.salesOffice = office;
        wrapper.order.currencyIsoCode = curency;
        wrapper.order.email = Userinfo.getUserEmail();
        wrapper.order.items = new List<OrderItem>();

        for (PricebookEntry prod : productItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.productCode = prod.ProductCode;
            orderItem.unit = prod.Uprice__c;
            orderItem.quantity = 1;
            wrapper.order.items.add(orderItem);
        }

        return wrapper;
    }

    private static OrderWrapper listToWrapperFactory(String sapId, String org, String channel, List<PricebookEntry> productItems) {
        OrderWrapper wrapper = new OrderWrapper();
        wrapper.order = new OrderHeader();
        wrapper.order.operationType = '20';
        wrapper.order.dateParam = System.today();
        wrapper.order.reference = 'TEST ORDER';
        wrapper.order.requestedBy = sapId;
        wrapper.order.salesOrg = org;
        wrapper.order.channel = channel;
        wrapper.order.email = Userinfo.getUserEmail();
        wrapper.order.items = new List<OrderItem>();

        for (PricebookEntry prod : productItems) {
            OrderItem orderItem = new OrderItem();
            orderItem.productCode = prod.ProductCode;
            orderItem.unit = prod.Uprice__c;
            orderItem.quantity = 1;
            wrapper.order.items.add(orderItem);
        }

        return wrapper;
    }

    public static Map<String, Decimal> getMaterialNetPrices(String jsonInput) {
        List<SapOrderResponse> responseList = (List<SapOrderResponse>) JSON.deserialize(jsonInput, List<SapOrderResponse>.class);
    
        Map<String, Decimal> materialToPrice = new Map<String, Decimal>();

        if (responseList != null && !responseList.isEmpty()) {
            SapOrderResponse response = responseList[0];

            if (response.sapOrder != null && response.sapOrder.items != null) {

                for (SapOrderResponseItem item : response.sapOrder.items) {
                    materialToPrice.put(item.material, item.netPrice);
                }
            }
        }

        return materialToPrice;
    }

    public class OrderWrapper {
        public OrderHeader order;
    }

    public class OrderHeader {
        public String operationType;

        @JsonProperty('date')
        public Date dateParam;
        public String reference;
        public String requestedBy;
        public String salesOrg;
        public String channel;
        public String salesOffice;
        
        @JsonProperty('currency')
        public String currencyIsoCode;   // ✅ variable interna apex
        public String email;
        public List<OrderItem> items;
    }
    
    public class OrderItem {
        public String productCode;
        public String unit;
        public Integer quantity;
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
    }*/
    
}