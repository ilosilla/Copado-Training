@RestResource( urlMapping = '/v1/Account/Validation')
global class AccountValidation_RESTAPEX {
	
    private static final String SALES_RELATIONSHIP = 'Sales_Relationship__c';
    private static final String ACCOUNT = 'Account';
    
    @HttpPost
    global static Response validateAccount() {
        System.debug('validateAccount');
        Response response = new Response();

        try {   
            String postBody = RestContext.request.requestbody.tostring();     
            System.debug('postBody=> '+postBody);        
            response = runValidation(postBody);
        } catch (Exception e) {
           response.errorMessage = e.getMessage();
           response.success = false;
        }
        
        return response;
        
    }


    public static Response runValidation(String inputJson){

        System.debug('runValidation');
        Response response = new Response();	
        response.success = false;
        SavePoint sp = Database.setSavePoint();

        try {
           
            System.debug('inputJson=> '+inputJson);

            AccountToSAP_Wrapper accountWrapper = (AccountToSAP_Wrapper) JSON.deserialize(inputJson, AccountToSAP_Wrapper.class);
            System.debug('deserialized=> '+accountWrapper);
            
            response.errorMessage = executeUpsert(accountWrapper).get('errorMessage');
            
            if(String.isBlank(response.errorMessage)){
                response.success = true;
            }

        } catch (Exception e) {
           response.errorMessage = e.getMessage();
        }
        
        Database.rollback(sp);
        System.debug('rollback response=>'+response);
        return response;
    }

    public static Map<String,String> executeUpsert(AccountToSAP_Wrapper accountWrapper){
        System.debug('executeUpsert accountWrapper => '+accountWrapper);
        Map<String,String> resultMap = new Map<String,String>();
        String errorMessage = '';
        if(accountWrapper.customer != null){
            System.debug('Final Upsert for Customer');
            // Modificado 31/05. Upsert se separa como insert y update para poder pasar como parametro DMLOptions para saltear la restriccion de duplicados.
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = false;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            
            Database.SaveResult customerResult = accountWrapper.customer.Id == null ? 
                Database.insert(accountWrapper.customer, dml) 
                : Database.update(accountWrapper.customer, dml);
                
            if (customerResult.isSuccess()){
                resultMap.put('custId',customerResult.getId());
            }else{
                for(Database.Error err : customerResult.getErrors()) {
                    errorMessage +=  err.getMessage()+'. ';
                    errorMessage += Label.Affected_Account_Fields + getFieldLabels(err.getFields(),ACCOUNT)+'\n';
                    System.debug('Customer upser errorMessage=> '+err.getStatusCode()+':'+errorMessage);
                }
            }
            
        }
        if(accountWrapper.companies != null){
            System.debug('Final Upsert for Company');
            Database.UpsertResult companyResult = Database.upsert(accountWrapper.companies[0], false);
            if (companyResult.isSuccess()) {
                resultMap.put('compId',companyResult.getId());
            }else{
                for(Database.Error err : companyResult.getErrors()) {
                    errorMessage +=  err.getMessage()+'. ';
                    errorMessage += Label.Affected_Sales_Relationship_Fields + getFieldLabels(err.getFields(),SALES_RELATIONSHIP)+'\n';
                    System.debug('Company upser errorMessage=> '+err.getStatusCode()+':'+errorMessage);
                }
            }
        }
        resultMap.put('errorMessage',errorMessage);
        System.debug('executeUpsert resultMap=> '+resultMap);

        return resultMap;
    }
    
    public static List<String> getFieldLabels(List<String> fieldNames, String objectName){
        List<String> fieldLabels = new List<String>();
        for(String fieldName : fieldNames){
            fieldLabels.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel());
        }
        return fieldLabels;
    }



    global class Response {

        global Boolean success;
        global String errorMessage;
        global String sapId;
        global Response(){}
        global Response(Boolean aSuccess, String aMessage){
            this.success = aSuccess;
            this.errorMessage = aMessage;
        }
    }

}