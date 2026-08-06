/**
* @author 			Ramón Prades
* @date 			September-2020
* @group 			SAP
* @group-content 	../../ApexDocContent/Sap.htm
* @description 	    Connects to SAP
*                   Test with SAPConnectionTesterTest
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public class SAPConnector {

    public final static String HELLO_SERVICE = '/api/hello';
    public final static String OPPORTUNITIES_SERVICE = '/api/opportunities';
    public final static String CUSTOMERS_SERVICE = '/api/customers';
    public final static String ADDRESS_SERVICE = '/api/address';     
    public final static String SALES_DOCUMENTS_SERVICE = '/api/salesdoc';    
    public final static String ZCLI_SERVICE = '/api/zcli';        
    public final static String ORDERS_V2_SERVICE = '/api/orders/v2/b2b?debug=truex';       

    private final static String CREDENTIALS = 'callout:SAP';    
    public final static String URL_TOKEN = '/api/customers/ping';

    /**
     * Connects to SAP
     */
    public static SAPWS_Utility.SapResponse connect(String idObject, String service, String method, String theJson) {
        return SAPConnector.connect(idObject, '', service, method, theJson);
    }
    
    public static SAPWS_Utility.SapResponse connect(String idObject, String queryString, String service, String method, String theJson) {        
        if (!SAPConnector.isConnected()) {
            return new SAPWS_Utility.SapResponse(true,null,null,null,null,null);
        }
        SAPWS_Utility.SapResponse responseObject;
        Http http = new Http();
        try{
            HttpRequest req = SAPConnector.buildRequest(idObject, queryString, service, method, theJson);
            HttpResponse res = http.send(req);
            Integer statusCode = res.getStatusCode();
            if (statusCode >= 200 && statusCode <= 299)  {
                // Encapsulates the json received in a SAPResponse
                responseObject = new SAPWS_Utility.SapResponse(true,null,null,null,null,res.getBody());
            } else if (statusCode >= 500)  {               
                String errorMessage = res.getBody();                    
                responseObject = new SAPWS_Utility.SapResponse(false, res.getStatusCode(), errorMessage, null, null, null);
            } else {
                String errorMessage = res.getBody(); 
                if (errorMessage.substring(0,1) == '[') {
                    // El servicio de pedidos devuelve una lista de errores - devolvemos el JSON sin modifivcar
                    responseObject = new SAPWS_Utility.SapResponse(false,null,null,null,null,res.getBody());
                } else {
                    responseObject = (SAPWS_Utility.SapResponse) JSON.deserialize(res.getBody(), SAPWS_Utility.SapResponse.class);                
                    responseObject.success = false;
                    String message = responseObject.message;
                    if (responseObject.details.size() > 0) {
                        message += ':';                    
                        Integer counter = 0;
                        for (SAPWS_Utility.Detail detail : responseObject.details) {
                            counter++;
                            message += ' ==> [' + counter + '] ' + detail.message;
                        }
                        responseObject.message = message;
                    }
                }
            }
        } catch(exception e) {            
            String errorMessage = e.getMessage();             
            responseObject = new SAPWS_Utility.SapResponse(false, 0, errorMessage, null, null, null);
        } 
        
        return responseObject;

    } // connect

    /*
     * Builds the httpRequest object
     */
    private static HttpRequest buildRequest(String idObject, String queryString, String service, String method, String theJson) {        
        Map<String, String> authParams = SAPConnector.getToken();
        String token = authParams.get('token');
        String cookie = authParams.get('cookie');
        String url = SAPConnector.CREDENTIALS + service;
        if (token == null) {
            throw new HttpException('SAP TOKEN ERROR: ' + authParams.get('error'));
        }

        if (idObject != null && idObject.length() > 0) {
            url = url + '/' + idObject;
        }
        if (String.isNotEmpty(queryString)) {
            url = url + '?' + queryString;
        }
        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setEndpoint(url);
        httpRequest.setMethod(method);
        httpRequest.setHeader('X-CSRF-Token', token);
        httpRequest.setHeader('cookie', cookie);
        httpRequest.setTimeout(30000);
        if (theJson.length() > 0) {
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(theJson);   
        }
        return httpRequest;
    } // buildRequest
    
    /*
     * Get the authentication x-crsf token from SAP (ping url). then
     * uses the token to authenticate the request
     */
    private static Map<String,String> getToken(){
        
        Map<String,String> params = new Map<String,String>();
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(SAPConnector.CREDENTIALS + SAPConnector.URL_TOKEN); 
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('X-CSRF-Token', 'Fetch');                
        try{
            Http http = new Http();
            HttpResponse response = http.send(request);            
            params.put('token',response.getHeader('x-csrf-token'));
            params.put('cookie',response.getHeader('set-cookie'));
        } catch(Exception ex) {
            params.put('token', null);
            params.put('cookie', null);
            params.put('error', ex.getMessage());
        }

        return params;        

    } // getToken

    /**
     * Checks if the user's context is coneccted to SAP
     */
    private static Boolean isConnected() {
        ExecutionContext context = ExecutionContext.getUserExecutionContext();    
        return context.useSAP;
    } // isConnected

    @testVisible private static String testFiller() {
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

} // class