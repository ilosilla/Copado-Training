public class OpportunityTransactionHandler {
    
    public static SAPWS_Utility.SapResponse runSAPValidation(String opportunityWrapperJSON){
        System.debug('START SAPValidation');

        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        if (!context.useSAP) {
            return  new SAPWS_Utility.SapResponse(true,null,null,null,null,null);
        }

        SAPWS_Utility.SapResponse responseObject;
        
        Map<String,String> params = SAPWS_Utility.getParams();
        if(params.get('token') == null || params.get('cookie')==null){
           	String errorMessage = Label.Unexpected_Error + ' ' + params.get('error') + '. ' + Label.Missing_Headers;
			responseObject = new SAPWS_Utility.SapResponse(false,null,errorMessage,null,null,null);
            System.debug('errorMessage=> '+errorMessage);
           
        }else{
            HttpRequest req = SAPWS_Utility.getSapRequestOpp(params,opportunityWrapperJSON);

            Http h = new Http();

            try{
                HttpResponse res = h.send(req);
                System.debug('code: '+res.getStatusCode()+' . Body: '+res.getBody());

                if (res.getStatusCode() >= 500) {
                    String errorMessage = Label.Unexpected_Error + res.getStatusCode() + ' - ' + res.getStatus();             
                    responseObject = new SAPWS_Utility.SapResponse(false,res.getStatusCode(),res.getStatus(),null,null,null);
                    System.debug('code 50x errorMessage=> '+errorMessage);
                }else if(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 204) {
                    responseObject = (SAPWS_Utility.SapResponse)JSON.deserialize(res.getBody(), SAPWS_Utility.SapResponse.class);
                    responseObject.success = false;
                    System.debug('NOK errorMessage=> '+res.getStatusCode() + ' - ' + res.getStatus());
                }else{
                    responseObject = new SAPWS_Utility.SapResponse(true,null,null,null,null,res.getBody());
                }
            }catch(exception e){
                String errorMessage = Label.Unexpected_Error + e.getMessage();             
                responseObject = new SAPWS_Utility.SapResponse(false,null,errorMessage,null,null,null);
                System.debug('Exception errorMessage=> '+errorMessage);
            }
        }
        System.debug('SapResponse=> '+responseObject);
        return responseObject;
        
    }

}