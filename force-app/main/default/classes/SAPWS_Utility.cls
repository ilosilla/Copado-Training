/*
Utility class to provide functionality to the SAP connectivity
*/
public class SAPWS_Utility {
    private final static String SAP_PATH_1 = '/api/customers/';
    private final static String SAP_PATH_2 = '/api/customers';
    private final static String SAP_PATH_3 = '/api/customers/ping';
    // 4/22/2019
    private final static String SAP_PATH_4 = '/api/opportunities';
    
    public static AccountToSAP_Wrapper accountWrapper;
    public static OpportunityToSAP_Wrapper opportunityWrapper;
    
    public static Map<String,String> getParams(){
        Logger.info('[SAP] - Auth - [Start]').addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        //build de request
        Map<String,String> params = new Map<String,String>();
        HttpRequest req = new HttpRequest();
        NB2B_SAP_Mocking__c mocking = NB2B_SAP_Mocking__c.getInstance();
        String endPoint = 'callout:' + ((mocking!= null && mocking.Active__c)? mocking.Named_Credential__c : 'SAP') + SAP_PATH_3;
        req.setEndpoint(endPoint); // using named credentials
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-CSRF-Token', 'Fetch');
        Logger.info('[SAP] - Auth - [Request]: ' + req);
        Http http = new Http();
        HttpResponse response;
        
        try{
            response = http.send(req);
            Logger.info('[SAP] - Auth - [Response]: ' + response).addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
            if(response.getStatusCode() != 200){ throw new SAPWS_AuthException(response.getStatusCode() + ' ' + response.getStatus());}
            Logger.info('[SAP] - Auth - [Response Body]: ' + response.getBody()).addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
            
            params.put('token',response.getHeader('x-csrf-token'));
            params.put('cookie',response.getHeader('set-cookie'));
        } catch(Exception ex) {
            Logger.error('[SAP] - Auth - [Error]: ' + ex.getMessage()).addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG);
            params.put('token', null);
            params.put('cookie', null);
            params.put('error', ex.getMessage());
        }
        Logger.info('[SAP] - Auth - [End]').addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);

        return params;
        
    }

    public static AccountToSAP_Wrapper getAccountWrapper(String accountWrapperJSON){
        if (accountWrapper == null) {
            accountWrapper = (AccountToSAP_Wrapper) JSON.deserialize(accountWrapperJSON, AccountToSAP_Wrapper.class);
        }
        System.debug('get accountWrapper=> '+accountWrapper);
        return accountWrapper;
    }
    
    public static OpportunityToSAP_Wrapper getOpportunityWrapper(String opportunityWrapperJSON){
        if (opportunityWrapper == null) {
            opportunityWrapper = (OpportunityToSAP_Wrapper) JSON.deserialize(opportunityWrapperJSON, OpportunityToSAP_Wrapper.class);
        }
        System.debug('get opportunityWrapper=> '+opportunityWrapper);
        return opportunityWrapper;
    }

    public static HttpRequest getSapRequest(Map<String, String> params, String json){
        HttpRequest req = new HttpRequest();

        accountWrapper = getAccountWrapper(json);
        //1- No company then we are editing a customer, as creating new ones follows the standard
        if(accountWrapper.companies == null){
            System.debug('PUT Customer, no company');
            req.setEndpoint('callout:SAP'+SAP_PATH_1+accountWrapper.customer.SAP_Id__c);
            req.setMethod('PUT');
        //2- If we have companies, and the customer has sap id, then we are either creating an additional
        // sales relation (not the fist one) or updating an existing one. For SAP both actions require a PUT 
        }else if(String.isNotBlank(accountWrapper.customer.SAP_Id__c)){ 
            System.debug('PUT Customer, with new additional company or updating existing one');
            req.setEndpoint('callout:SAP'+SAP_PATH_1+accountWrapper.customer.SAP_Id__c);
            req.setMethod('PUT');
        //If there are companies but no sap id, then we are creating the customer in SAP for first time
        //along with the sales relationhip
        }else{
            System.debug('POST customer with first company');
            req.setEndpoint('callout:SAP'+SAP_PATH_2);
            req.setMethod('POST');
        }


        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-CSRF-Token', params.get('token'));
        req.setHeader('cookie', params.get('cookie'));

        req.setBody(json);
        System.debug('req=> '+req);
        System.debug('JSON=> '+json);

        return req;
    }
    
    public static HttpRequest getSapRequestOpp(Map<String, String> params, String json){
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint('callout:SAP'+SAP_PATH_4);
        req.setMethod('PUT');

        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-CSRF-Token', params.get('token'));
        req.setHeader('cookie', params.get('cookie'));

        req.setBody(json);
        System.debug('req=> '+req);
        System.debug('JSON=> '+json);

        return req;
    }


    public class SapResponse {
        @AuraEnabled public boolean success;
        @AuraEnabled public Integer code;
        @AuraEnabled public String message;
        @AuraEnabled public List<Detail> details;
        @AuraEnabled public String target;
        @AuraEnabled public String json;
        @AuraEnabled public Blob binary;
        @AuraEnabled public boolean isValidationError;

        public SapResponse(Boolean success, Integer code, String message, List<Detail> aDetails, String target, String json){
            this.success=success;
            this.code=code;
            this.message=message;
            this.details = aDetails;
            this.target=target;
            this.json=json;
            this.isValidationError=false;
        }
 
    }

    public class Detail{
        public String code;
        public String level;
        public String message;
        public Detail(String aCode, String aLevel, String aMessage){
            this.code = aCode;
            this.level = aLevel;
            this.message = aMessage;
        }
    }

    private class SAPWS_AuthException extends Exception {}
}