/**
* @author 			Ramón Prades
* @date 			May 2023
* @group 			SAP
* @description 	    Class to access SAP web services. It is the evolution of SAPConnector.cls.
*/
public class SAPProxy {

    // Public properties
    public String resourceId;   // Resource ID (it's added to the service URL)
    public String queryString;  // Added to the URL
    public String method = 'GET';           
    public String inputJSON;
    public Boolean isConnected = false; // True if the user's context is connected to SAP

    // Result public variables
    public Integer statusCode;
    public String receivedJSON;
    public Blob receivedBlob;
    public Boolean success = false;
    public Boolean isBlob = false;

    // Available services
    public final static String HELLO_SERVICE = '/api/hello';
    public final static String OPPORTUNITIES_SERVICE = '/api/opportunities';
    public final static String CUSTOMERS_SERVICE = '/api/customers';
    public final static String ADDRESS_SERVICE = '/api/address';     
    public final static String SALES_DOCUMENTS_SERVICE = '/api/salesdoc';    
    public final static String SALES_DOCUMENTS_SERVICE_V2 = '/api/v2/salesdoc';  
    public final static String ZCLI_SERVICE = '/api/zcli';        
    public final static String ORDERS_V2_SERVICE = '/api/orders/v2/b2b';           

    // Private variables
    private final static String CREDENTIALS = 'callout:SAP';    
    private final static String URL_TOKEN = '/api/customers/ping';
    private String service;      // Web Service
    private String url;

    /**
     * Constructor
     */
    public SAPProxy(String service) {
        this.service = service;
        this.isConnected = this.isConnectedToSAP();
    }

    /**
     * Connects to SAP. Returns the HTTP status received
     */    
    public Boolean connectToSAP() {   
        String info = '';
        if (!this.isConnected) {
            throw new ContextException('SAP not available in this execution context');
        }

        Http http = new Http();
        this.success = false;
        this.isBlob = false;
        try {
            HttpRequest req = this.buildRequest();
            HttpResponse res = http.send(req);
            this.statusCode = res.getStatusCode();            
            this.success = (this.statusCode >= 200 && this.statusCode <= 299);   
            for (String key :res.getHeaderKeys()) {
                if (key.toLowerCase() == 'content-type') {
                    String contentType = res.getHeader(key);
                    this.isBlob = contentType?.toLowerCase().contains('application/pdf') ?? false;
                }
            }
            if (this.isBlob) {
                this.receivedBlob = res.getBodyAsBlob();
            } else {                
                this.receivedJSON = res.getBody();
            }
        } catch(exception e) {      
            throw new HttpException(e.getMessage());    
        }         
        return this.success;
    } // connect

    public List<SAPResponse> getResponse() {
        return (List<SAPResponse>) JSON.deserialize(this.receivedJSON, List<SAPResponse>.class);
    }

    ////////////////////////////////////////////////////////////////////
    //// PUBLIC CLASSES (DATATYPES)
    ////////////////////////////////////////////////////////////////////
    public class SAPResponseError {
        public String id;
        public String type;
        public String message;
    }

    public class SAPResponse {
        public Integer index;
        public Boolean success;
        public SAPProxy.SAPResponseError error;
    }

    ////////////////////////////////////////////////////////////////////
    //// PRIVATE METHODS
    ////////////////////////////////////////////////////////////////////
    /*
     * Builds the httpRequest object
     */
    private HttpRequest buildRequest() {        
        Map<String, String> authParams = this.getToken();
        String token = authParams.get('token');
        String cookie = authParams.get('cookie');
        this.url = SAPProxy.CREDENTIALS + service;
        if (token == null) {
            throw new HttpException('SAP TOKEN ERROR: ' + authParams.get('error'));
        }

        if (String.isNotBlank(this.resourceId)) {
            this.url += '/' + this.resourceId;
        }
        if (String.isNotBlank(this.queryString)) {
            url += '?' + this.queryString;
        }
        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setEndpoint(this.url);
        httpRequest.setMethod(this.method);
        httpRequest.setHeader('X-CSRF-Token', token);
        httpRequest.setHeader('cookie', cookie);
        httpRequest.setTimeout(30000);
        if (String.isNotBlank(this.inputJSON) ) {
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(this.inputJSON);   
        }
        return httpRequest;
    } // buildRequest
    
    /*
     * Get the authentication x-crsf token from SAP (ping url). then
     * uses the token to authenticate the request
     */
    private  Map<String,String> getToken(){
        
        Map<String,String> params = new Map<String,String>();
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(SAPProxy.CREDENTIALS + SAPProxy.URL_TOKEN); 
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('X-CSRF-Token', 'Fetch');                
        try{
            Http http = new Http();
            HttpResponse response = http.send(request);            
            String resBody = response.getBody();
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
    private Boolean isConnectedToSAP() {
        ExecutionContext context = ExecutionContext.getUserExecutionContext();    
        return context.useSAP;
    } // isConnected

} // class