/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 02-10-2023
 * @last modified by  : EHG@nubika.com
**/
public with sharing class NB2B_StockCallOut {

    private String productCode;
    private String salesOrganization;

    public NB2B_StockCallOut(String productCode, String salesOrganization) {
        this.productCode=productCode;
        this.salesOrganization=salesOrganization;
    }

    public List <NB2B_StockCallOutResponse> callOut(){
        Http http=new Http();
        HttpRequest request=new HttpRequest();
        List<NB2B_StockCallOutResponse> response;

        Map<String,String> params = SAPWS_Utility.getParams();
        String token = params.get(Nb2b_GlobalConstants.TOKEN_NAME);
        String cookie = params.get(Nb2b_GlobalConstants.COOKIE_NAME);

        request.setEndpoint('callout:SAP/api/stock/sales-org/' + salesOrganization + '/' + productCode);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('x-csrf-token', token);
        request.setHeader('cookie', cookie);
     
        System.debug('******SERVICIO DE STOCK*******');
        System.debug('http.send(request).getBody():'+http.send(request).getBody());
        try{
            response = (List<NB2B_StockCallOutResponse>) JSON.deserialize(http.send(request).getBody(), List<NB2B_StockCallOutResponse>.class);

        System.debug('****Response****:'+response);
        }catch(Exception e){
            NB2B_StockCallOutManagerHelper.nebulaError(e.getMessage());
        }
        return response;
    }

    public class NB2B_StockCallOutResponse{
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
    }
}