@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        HttpResponse res = new HttpResponse();
        
        if ( req.getMethod().equals('GET') ){
            
            if(req.getEndpoint().contains('/api/customers/ping') ){
                res.setHeader('x-csrf-token', 'token churro');
                res.setHeader('set-cookie', 'cookie churrito');
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
            }
            
            // Create a fake response
            //res.setBody('{"companies":[{"account_org__c":"001900000000000000","commercial__c":"0051w000000maBHAAY","credit__c":false,"currency__c":"GBP","custom_id__c":"001900000000000000-502-60","distribution_channel__c":"60","relationship__c":"Z4","sales_office__c":"2553","sales_org__c":"502"}],"customer":{  "billingcity":"Bristol","billingcountrycode":"GB","billingpostalcode":"BS1 3NZ","billingstatecode":"AB","billingstreet":"9 HIGH STREET","business_email__c":"david@subway.com","id":"001900000000000000","ispersonaccount":false,"name":"TEST E2E","ownerid":"0051w000000kwURAAY","phone":"769877788","recordtypeid":"0121w0000004VDTAA2","sap_id__c":"0001086108","vat_number__c":"726416242"}}');
        }
        
        if ( req.getMethod().equals('POST') ){
            // Create a fake response for sf Validation
            if(req.getEndpoint().contains('apexrest')){
                AccountValidation_RESTAPEX.Response SfValidationResponse = new AccountValidation_RESTAPEX.Response(true, null);
                res.setBody(JSON.serialize(SfValidationResponse));
                res.setStatusCode(200);
                // Create a fake response for sap Validation
            } else{
                res.setBody('{"customer":{"Sap_Id__c":"123456789"}}');
                res.setStatusCode(200);
            }
            
            if( req.getEndpoint().contains('/api/customers') ){
                AccountToSAP_Wrapper sapWrapper = (AccountToSAP_Wrapper) JSON.deserialize(req.getBody(), AccountToSAP_Wrapper.class);
                System.debug('sapWrapper: ' + sapWrapper);
                
                if(sapWrapper.companies != null){
                    System.debug('companies: ' + sapWrapper.companies[0]);
                    if(sapWrapper.companies[0].Relationship__c != 'Z4' ){
                        res.setStatusCode(400);
                        res.setBody('{"code":400, "message":"Relationship es un campo requerido", "details": [{"message": "null", "code" : "null", "level" : "null"}], "target":"/api/customers"}');
                    }
                }
                
            }
            
        }
        System.debug('Body: ' + req.getBody());
        if ( req.getMethod().equals('PUT') ){
            if(req.getEndpoint().contains('api/customers')){
                if(req.getBody() == '{}'){
                    res.setStatusCode(202);
                    res.setBody('{}');
                } else if (req.getBody() == '{"customer": "Bad Input"}'){
                    res.setStatusCode(600);
                    res.setBody('{}');
                } else {
                    //res.setBody('{"customer":{"Sap_Id__c":"123456789"}}');
                    res.setStatusCode(200);
                }
            } else if(req.getEndpoint().contains('/api/opportunities')){
                if( String.isBlank(req.getBody()) ){
                    res.setStatusCode(400);
                } else {
                    
                    try{
                        OpportunityToSAP_Wrapper sapWrapper = (OpportunityToSAP_Wrapper) JSON.deserialize(req.getBody(), OpportunityToSAP_Wrapper.class);
                        // Si la oportunidad es nula o la lista de oportunity actors es nula o vacia se devuelve un codigo de error.
                        if(sapWrapper.opportunity == null || sapWrapper.opportunityActorsList == null 
                           ||  sapWrapper.opportunityActorsList.isEmpty() ){
                               res.setStatusCode(400);
                           } else {
                               res.setStatusCode(204);
                           }
                        
                    } catch (Exception ex){
                        System.debug('Opportunity Mock error: ' + ex.getMessage() );
                        res.setStatusCode(400);
                    }
                    
                } 
            }
            
        }
        
        System.debug('MOCK res=> ' +res);
        
        
        return res;
    }
}