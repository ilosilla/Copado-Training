/*-----------------------------------------------------------------------------------------
Author:         
Company:        Neoris
Date:           
Description:    Manages all account related communication with SAP
Test Class:     AccountTransactionHandlerTest
History
<Date>            <Author>              <Change Description>
26/07			Juan Manuel Martinez	Si no se especifica un timeout (timeout = 0) se toma el valor por default
-----------------------------------------------------------------------------------------*/

public class AccountTransactionHandler {
    
    public static TransactionResponse runTransaction(String accountWrapperJSON){
        TransactionResponse txResponse;

        System.debug('START runTransaction');
        System.debug('accountWrapperJSON '+ accountWrapperJSON);
        String errorTitle='';
        String errorMessage='';
        
        //-----Validate in SF everything contained inside the wrapper - insert + rollback
        AccountValidation_RESTAPEX.Response sfResponse = runSfValidation(accountWrapperJSON);

        if(!sfResponse.success){
            errorTitle = Label.Error_On_SF_Validation;
            errorMessage =  sfResponse.errorMessage;
            txResponse = new TransactionResponse(false,errorTitle,errorMessage,null,null);
            return txResponse;
        }
        System.debug('SF VALIDATION OK');
		
        //-------Validate with SAP
        SAPWS_Utility.SapResponse sapResponse = runSAPValidation(accountWrapperJSON, 0);

        if(!sapResponse.success){
            errorTitle = Label.Error_On_SAP_Validation;
            if(sapResponse.details != null){
                errorMessage = sapResponse.details[0].message+'. ';
            }
            errorMessage += '( '+sapResponse.message +'. code: '+sapResponse.code+' ).';
            txResponse = new TransactionResponse(false,errorTitle,errorMessage,null,null);
            return txResponse;
        }
        System.debug('SAP VALIDATION OK');

        //----If all validations run fine - Final insert ---------------------------------
        try{
            AccountToSAP_Wrapper accountWrapper = SAPWS_Utility.getAccountWrapper(accountWrapperJSON);

            //If there is customer and...
            if(accountWrapper.customer != null){
                //... it has no SAP id yet, we are creating first sales relation, so we should get a SAP id
                //in the reponse body
                if(String.isBlank(accountWrapper.customer.Sap_Id__c)){
                    AccountToSAP_Wrapper reponseSapWrapper = (AccountToSAP_Wrapper) JSON.deserialize(sapResponse.json, AccountToSAP_Wrapper.class);
                    accountWrapper.customer.Sap_Id__c = reponseSapWrapper.customer.Sap_Id__c;
                    System.debug('Saving SAP Id=> '+accountWrapper.customer.Sap_Id__c);
                }
            }
            
            // Agregado Juan Manuel 29/05
            if( accountWrapper.companies != null && !accountWrapper.companies.isEmpty() ){
                accountWrapper.companies[0].Sap_Status__c = 'Success';
                accountWrapper.companies[0].Error_Message__c = null;
            }
            // 
            
            Map<String,String> upsertResults = AccountValidation_RESTAPEX.executeUpsert(accountWrapper);

            if(String.isBlank(upsertResults.get('errorMessage'))){
                txResponse = new TransactionResponse(true,null,null,upsertResults.get('custId'),upsertResults.get('compId'));
            }else{
                txResponse = new TransactionResponse(false,Label.Unexpected_Error,upsertResults.get('errorMessage'),null,null);
                //send email to admin because SAP and SF may be out of sync
                createAlert(accountWrapper, upsertResults.get('errorMessage'));
            }
        }catch(Exception e){
            txResponse = new TransactionResponse(false,Label.Unexpected_Error, e.getMessage(),null,null);
            //send email to admin because SAP and SF may be out of sync
        }
        
        System.debug('txResponse=> '+txResponse);
        
        return txResponse;
        
    }
    
    public static AccountValidation_RESTAPEX.Response runSfValidation(String accountWrapperJSON){
        
        System.debug('START runSfValidation');
        AccountValidation_RESTAPEX.Response responseObject;
        
        Httprequest req = new Httprequest();
        req.setMethod('POST');
        req.setEndpoint('callout:SFToken/services/apexrest/v1/Account/Validation');
        req.setHeader('Content-Type','application/json');
        req.setBody(accountWrapperJSON);
        System.debug('req validation=>'+req);
        
        Http h = new Http();
        try{
            HttpResponse response = h.send(req);
            if (response.getStatusCode() != 200) {
                String errorMessage = Label.Unexpected_Error + response.getStatusCode() + ' - ' + response.getStatus();             
                responseObject = new AccountValidation_RESTAPEX.Response(false,errorMessage);
                System.debug('errorMessage=> '+errorMessage);
            }else{
                String resBody = response.getBody();
                responseObject = (AccountValidation_RESTAPEX.Response)JSON.deserialize(resBody, AccountValidation_RESTAPEX.Response.class);
                System.debug('responseObject=> '+responseObject);
            }
        }catch(exception e){
            String errorMessage = Label.Unexpected_Error + e.getMessage();             
            responseObject = new AccountValidation_RESTAPEX.Response(false,errorMessage);
            System.debug('errorMessage=> '+errorMessage);
        }
        
        return responseObject;
    }
    
    public static SAPWS_Utility.SapResponse runSAPValidation(String accountWrapperJSON, Integer timeOut){
        System.debug('START SAPValidation');
        SAPWS_Utility.SapResponse responseObject;
        
        Map<String,String> params = SAPWS_Utility.getParams();
        if(params.get('token') == null || params.get('cookie')==null){
           	String errorMessage = Label.Unexpected_Error + ' ' + params.get('error') + '. ' + Label.Missing_Headers;
			responseObject = new SAPWS_Utility.SapResponse(false,null,errorMessage,null,null,null);
            System.debug('errorMessage=> '+errorMessage);
           
        }else{
            HttpRequest req = SAPWS_Utility.getSapRequest(params,accountWrapperJSON);
            
            // Cambio 26/07. Si no se especifica un timeout (timeout = 0) se toma el valor por default
            if(timeout != 0){
                req.setTimeout(timeOut);
            }
            
            Http h = new Http();

            try{
                //req.setTimeout(1);
                HttpResponse res = h.send(req);
                System.debug('code: '+res.getStatusCode()+' . Body: '+res.getBody());
                
                if (res.getStatusCode() >= 500) {
                    String errorMessage = Label.Unexpected_Error + res.getStatusCode() + ' - ' + res.getStatus();             
                    responseObject = new SAPWS_Utility.SapResponse(false,res.getStatusCode(),errorMessage,null,null,null);
                    System.debug('code 50x errorMessage=> '+errorMessage);
                }else if(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 204) {
                    responseObject = (SAPWS_Utility.SapResponse)JSON.deserialize(res.getBody(), SAPWS_Utility.SapResponse.class);
                    responseObject.success = false;
                    System.debug('NOK errorMessage=> '+res.getStatusCode() + ' - ' + res.getStatus());
                }else{
                    responseObject = new SAPWS_Utility.SapResponse(true,res.getStatusCode(),null,null,null,res.getBody());
                }
            }catch(exception e){
                String errorMessage = Label.Unexpected_Error + e.getMessage();             
                responseObject = new SAPWS_Utility.SapResponse(false,null,errorMessage,null,null,null);
                System.debug('Exception errorMessage=> '+errorMessage);

                Loggercommons.LogException('ACCOUNTSAPSYNC', accountWrapperJSON, e);

                Mail m = new Mail();
                m.setGeneric();
                m.setTo(new List<String>{'salesforce.dev@porcelanosagrupo.com'});
                m.setSubject('Error SAP Synchronization');
                m.setHtml(e.getMessage() + '<br><br>JSON<br>' + accountWrapperJSON);
                m.send();
            }
        }
        System.debug('SapResponse=> '+responseObject);
        return responseObject;
        
    }

    public class TransactionResponse{
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorTitle;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String customerId;
        @AuraEnabled public String companyId;
        public TransactionResponse(Boolean aSuccess, String aErrorTitle, String aErrorMessage, String aCustomerId, String aCompanyId){
            this.success = aSuccess;
            this.errorTitle = aErrorTitle;
            this.errorMessage = aErrorMessage;
            this.customerId = aCustomerId;
            this.companyId = aCompanyId;
        }
    }
    
    public static void createAlert(AccountToSAP_Wrapper accWrapper, String errorMessage){
        try{
            if(accWrapper.companies != null && !accWrapper.companies.isEmpty()){
                errorMessage += '. SAP ID: ' + accWrapper.customer.SAP_Id__c;
                
                String groupName = Test.isRunningTest() ? 'test group name' : [SELECT Group_Name__c FROM Sap_Errors_Group_Config__mdt 
                                                                               WHERE DeveloperName = 'Porcelanosa_Group'].Group_Name__c;
                Id chatterGroupId = [SELECT Id FROM CollaborationGroup WHERE Name =: groupName].Id;
                
                Insert AutomatismsNotifications.createChatterPost(chatterGroupId, accWrapper.companies[0], errorMessage);
                
            }
        } catch(Exception ex){
            System.debug('Error Creating notification: ' + ex.getMessage());
        }
        
    }
	
}