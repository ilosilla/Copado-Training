/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_OrderController
     Created Date:      7/02/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Order crontoller class
------------------------------------------------------------------------------------------*/
public class NB2B_OrderTransactionHandler {
    public static NB2B_OrderTransactionHandler.Response runTransaction(String orderWrapperJSON){
        return runSfValidation(orderWrapperJSON);
    }
    public static NB2B_OrderTransactionHandler.Response runSfValidation(String orderWrapperJSON){
        Logger.info('[SAP] - Order Creation Transaction - [Started]').addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        NB2B_OrderTransactionHandler.Response responseObject = new NB2B_OrderTransactionHandler.Response();
        String logMessage = '';
        try{
            Map<String,String> params = SAPWS_Utility.getParams();
            
            if(!params.containsKey(Nb2b_GlobalConstants.TOKEN_NAME) || String.isBlank(params.get(Nb2b_GlobalConstants.TOKEN_NAME))){
                Logger.error('[SAP] - Order Creation Transaction - [Error]: Unable to receive a valid Auth Token. Auth request results:\n' + JSON.serializePretty(params)).addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG);
                throw new OrderTransactionException(Label.NB2B_SAP_UnknownError);
            }

            String cookie = params.get(Nb2b_GlobalConstants.COOKIE_NAME);
            String token = params.get(Nb2b_GlobalConstants.TOKEN_NAME);

            NB2B_SAP_Mocking__c mocking = NB2B_SAP_Mocking__c.getInstance();
            String endPoint = 'callout:' + ((mocking!= null && mocking.Active__c)? mocking.Named_Credential__c : 'SAP') + '/porsa/orders/b2b';
            Httprequest req = new Httprequest();
            req.setMethod('POST');
            req.setEndpoint(endPoint);
            req.setHeader('x-csrf-token', token);
            req.setHeader('cookie', cookie);
            if (String.isNotBlank(orderWrapperJSON)) {
                req.setHeader('Content-Type', 'application/json');
                req.setBody(orderWrapperJSON);
            }
            logMessage += buildRequestLogMessage(req);

            //REAL INVOCATION
            Http h = new Http();
            HttpResponse res = h.send(req);
            logMessage += buildResponseLogMessage(res);

            String resBody = res.getBody();
            System.debug('NB2B_OrderTransactionHandler - runSfValidation() - resBody: ' + JSON.serialize(resBody));
            if(String.isNotBlank(resBody)){
                responseObject = (NB2B_OrderTransactionHandler.Response) JSON.deserialize(resBody, NB2B_OrderTransactionHandler.Response.class);
                System.debug('NB2B_OrderTransactionHandler - runSfValidation() - responseObject: ' + JSON.serialize(responseObject));
                responseObject.initialize();
            }else{
                throw new OrderTransactionException(Label.NB2B_SAP_UnknownError);
            }
        }catch(System.CalloutException e){
            responseObject = new NB2B_OrderTransactionHandler.Response(e.getMessage());
            responseObject.forceSuccessOutput = true;
            Logger.error('[SAP] - Order Creation Transaction - [Error]:' + e.getMessage() + '\n' + e.getStackTraceString()).addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG);
        }catch(Exception e){
            responseObject = new NB2B_OrderTransactionHandler.Response(e.getMessage());
            Logger.error('[SAP] - Order Creation Transaction - [Error]:' + e.getMessage() + '\n' + e.getStackTraceString()).addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG);
        }

        Logger.info('[SAP] - Order Creation Transaction - [Callout Detail]:\n' + logMessage).addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        responseObject.log();
        Logger.info('[SAP] - Order Creation Transaction - [Finished]').addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        Logger.saveLog();

        return responseObject;
    }

    private static String buildRequestLogMessage(HttpRequest req){
        String logMessage = '\nRequest\n';
        logMessage += '=======';
        logMessage += '[HttpMethod]          --> ' + req.getMethod() +'\n';
        logMessage += '[Header:x-csrf-token] --> ' + req.getHeader('x-csrf-token') + '\n';
        logMessage += '[Header:cookie]       --> ' + req.getHeader('cookie') + '\n';
        logMessage += '[Body]                --> ' + req.getBody() + '\n';
        return logMessage;
    }

    private static String buildResponseLogMessage(HttpResponse res){
        String logMessage = '\nResponse\n';
        logMessage += '=======\n';
        logMessage += '[Status] --> ' + res.getStatusCode() + ' ' + res.getStatus() + '\n';
        logMessage += '[Body]   --> ' + res.getBody() + '\n';
        return logMessage;
        }

    public class Response {
        //Integration attributes
        @AuraEnabled public Boolean Success = false;
        @AuraEnabled public Boolean forceSuccessOutput = false;
        @AuraEnabled public String OrderNumber;
        @AuraEnabled public String SamplesNumber;
        @AuraEnabled public String CustomerNumber;
        @AuraEnabled public String ShippingNumber;
        public List<ResponseError> Error = new List<ResponseError>();
        public List<ResponseError> errors = new List<ResponseError>();

        //Own attributes
        @AuraEnabled public String errorMessage;
        public NB2B_SAPOrderError__mdt errorDef;

        public Response(){
            this.initialize();
        }

        public Response(String errorMessage){
            this.errorMessage = errorMessage;
            this.initialize();
        }

        public Boolean isBlockOrder(){
            return !this.forceSuccessOutput && ((this.errorDef != null)?  this.errorDef.Block_Order__c: !this.Success);
        }

        private Boolean hasError(){
            return (this.Error!=null && !this.Error.isEmpty()) || (this.errors!=null && !this.errors.isEmpty());
        }
        private ResponseError getError(){
            if(this.hasError()){
                if(this.Error!=null && !this.Error.isEmpty()){
                    return this.Error.get(0);
                }else if(this.errors!=null && !this.errors.isEmpty()){
                    return this.errors.get(0);
                }
            }else{
                return null;
            }
            return this.hasError() ? this.Error.get(0) : null;
        }
        
        public void initialize(){
            this.forceSuccessOutput = false;
            ResponseError error = getError();
            this.errorDef = (error != null)? NB2B_SAPOrderError__mdt.getInstance(error.CODE.replace('-','_')) : null;
            setErrorMessage();
        }

        private void setErrorMessage(){
            if(this.errorDef != null){
                switch on (this.errorDef.Message_Type__c){
                    when 'Label' {
                        try{
                            this.errorMessage = System.Label.get(null,errorDef.Message__c,UserInfo.getLanguage());
                        }catch(Exception e){
                            this.errorMessage = getError().MESSAGE;
        }
    }
                    when 'Text'{
                        this.errorMessage = this.errorDef.Message__c;
                    }
                    when else{
                        this.errorMessage = getError().MESSAGE;
                    }
                }
            }
            this.errorMessage = (String.isBlank(this.errorMessage))? Label.NB2B_SAP_UnknownError : this.errorMessage;
        }

        public NB2B_CartToOrderManager.B2BCartToOrderOutput generateFlowOutput(){
            NB2B_CartToOrderManager.B2BCartToOrderOutput output = new NB2B_CartToOrderManager.B2BCartToOrderOutput();
            if(!this.Success && !this.forceSuccessOutput){
                output.errorTxt = this.errorMessage;
                output.displayType = (this.errorDef != null)? this.errorDef.Display_Type__c : 'Error';
                output.showError = (this.errorDef != null)? this.errorDef.Display_Message__c : true;
            }else{
                output.displayType = 'Success';
            }
            return output;
        }

        public void log(){
            if(this.errorDef != null){
                switch on (this.errorDef.Display_Type__c){
                    when 'Warning'{ Logger.warn('[SAP] - Order Creation Transaction - [Result]: ' + this.errorMessage + '\n' + JSON.serializePretty(this)).addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG); }
                    when else{ Logger.error('[SAP] - Order Creation Transaction - [Result]: ' + this.errorMessage + '\n' + JSON.serializePretty(this)).addTags(new List<String>{Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG,Nb2b_GlobalConstants.LOGGER_B2B_SEND_EMAIL}); }
                }
            }else{
                if(this.Success){
                    Logger.info('[SAP] - Order Creation Transaction - [Result]: \n' + JSON.serializePretty(this)).addTag(Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
                }else{
                    Logger.error('[SAP] - Order Creation Transaction - [Result]: ' + this.errorMessage + '\n' + JSON.serializePretty(this)).addTags(new List<String>{Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG,Nb2b_GlobalConstants.LOGGER_B2B_SEND_EMAIL});
                }
            }
        }
    }

    public class ResponseError{
        @AuraEnabled public String ID;
        @AuraEnabled public String CODE;
        @AuraEnabled public String TYPE;
        @AuraEnabled public String MESSAGE;
    }
	
    public class OrderTransactionException extends Exception {}
}