/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-13-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class NB2B_StockProductListCallOut {

    private List<String> productCodeList;
    private String salesOrganization;

    public NB2B_StockProductListCallOut(List<String> productCodeList, String salesOrganization) {
        this.productCodeList = productCodeList;
        this.salesOrganization = salesOrganization;
        System.debug('productCodeList: '+this.productCodeList);
        System.debug('productCodeList JSON.serialize: '+JSON.serialize(productCodeList));
        
        String body = JSON.serialize(productCodeList).replaceAll('productCodes', 'product');
        System.debug('body: '+body);
    }

    public List <NB2B_StockProductListCallOutResponse> callOut(){
        Http http=new Http();
        HttpRequest request=new HttpRequest();
        List<NB2B_StockProductListCallOutResponse> response;

        Map<String,String> params;
		String token;
        String cookie;
        
        try{
            
            if(!Test.isRunningTest()){
                params = SAPWS_Utility.getParams();
            	token = params.get(Nb2b_GlobalConstants.TOKEN_NAME);
            	cookie = params.get(Nb2b_GlobalConstants.COOKIE_NAME);    
            }else{
                token 	= 'test';
                cookie = 'test';
            }
            List<NB2B_StockProductListCallOutRequest> wrapperProductCodeList = new List<NB2B_StockProductListCallOutRequest> ();
            for (String productCode : productCodeList){
                wrapperProductCodeList.add(new NB2B_StockProductListCallOutRequest(productCode) );
            }
            String body = JSON.serialize(wrapperProductCodeList);
            System.debug('###request body: '+body);
    
            request.setEndpoint('callout:SAP/api/stock/sales-org/' + salesOrganization );
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('x-csrf-token', token);
            request.setHeader('cookie', cookie);
            request.setBody(body);
    
        
            String responseBody = http.send(request).getBody();
            System.debug('responseBody : ' + responseBody);
            // responseBody = '[{"available":true,"availstk":27105,"name":"FERROKER ALUMINIO 44X66(A)","product":"000000000100026606","salesorg":"502","totalstk":44704,"umb":"PZS","umbEn":"PZS","nextProduction":"2021-12-30","hideCheck":false, "quantity":0},{"available":false,"availstk":0,"name":"COLORSTUK 0-4 MOKA 5KG","product":"000000000100026607","salesorg":"502","totalstk":44704,"umb":"PZS","umbEn":"PZS","nextProduction":"","hideCheck":true, "quantity":0},{"available":false,"availstk":0,"name":"AMSTERDAM BLANCO 22X90(A)","product":"000000000101124185","salesorg":"502","totalstk":44704,"umb":"PZS","umbEn":"PZS","nextProduction":"2021-12-30","hideCheck":false, "quantity":0}]';
            if (!responseBody.contains('code')){
                response = (List<NB2B_StockProductListCallOutResponse>) JSON.deserialize(responseBody, List<NB2B_StockProductListCallOutResponse>.class);
                System.debug('NB2B_StockProductListCallOut entra response : ' + response);
            }else{
                response = new List<NB2B_StockProductListCallOutResponse>();
                NB2B_StockProductListCallOutResponse responseError = new NB2B_StockProductListCallOutResponse();
                responseError.error = responseBody;
                response.add(responseError);
            }
            
            System.debug('NB2B_StockProductListCallOut response: '+response);

        }catch(Exception e){
            NB2B_StockCallOutManagerHelper.nebulaError(e.getMessage());
            response = new List<NB2B_StockProductListCallOutResponse>();
            NB2B_StockProductListCallOutResponse responseError = new NB2B_StockProductListCallOutResponse();
            responseError.error = String.valueOf(e);
            response.add(responseError);
        }
        return response;
    }

    public class NB2B_StockProductListCallOutRequest {
        
        public String product {get;set;}
        
        public NB2B_StockProductListCallOutRequest (String productCode){
            product = productCode;
        }
        // public NB2B_StockProductListCallOutRequest (List<String> productCodeList){
        //     this.productList.addAll(productCodeList);
        // }
        
    }
   

    public class NB2B_StockProductListCallOutResponse {
        @AuraEnabled
        public Decimal availstk;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String product;
        @AuraEnabled
        public String salesorg;
        @AuraEnabled
        public Decimal totalstk;
        @AuraEnabled
        public String umb;
        @AuraEnabled
        public String umbEn;
        @AuraEnabled
        public String nextProduction;
        @AuraEnabled
        public Boolean available;
        @AuraEnabled
        public Boolean hideCheck;
        @AuraEnabled
        public Decimal quantity;
        @AuraEnabled
        public String error;
        /*NB2B_StockProductListCallOutResponse(){
            quantity = 0;
        }*/
    }
}