/**
 * @author         Ramón Prades
 * @date           September 2024
 * @layer          Interface
 * @description    Helper class for RESTOpenAPIV2Controller
*/
global class RESTOpenAPIV2Helper {

    global String resourceName { get; private set; }
    global String resourceId { get; private set; }
    global Map<String, String> params { get; private set; }
    global Integer statusCode { get; private set; }
    global String responseBody { get; private set; }
    global String contentType { get; private set; }

    private RestRequest request;
    private String method;
    private final String baseUri = '/openapi/v2/';

    global RESTOpenAPIV2Helper(RestRequest request, String method) {
        this.request = request;
        this.method = method.toUpperCase();
        this.extractUriParts();
    }

    global Boolean processResource() {
        Boolean success = true;
        if (this.resourceName == 'claim') {
            String approvedBy = params.get('approvedby');
            if (String.isBlank(approvedBy)) {
                this.statusCode = 400;            
                this.responseBody = 'Missing parameter "approvedBy"';
                success = false;
            } else {    
                SAPCasesService.approveCollection(this.resourceId, approvedBy);    // Same process for collections and claims
                this.responseBody = 'The claim has been succesfully approved!';
            }
        } else if (this.resourceName == 'debug') {
            this.processDebug();  
        } else if (this.resourceName?.toLowerCase() == 'payment-gateway-capture') {
            this.statusCode = B2B_PaymentGatewayCapture.handle(this.request);
            this.responseBody = 'Processed ok';
        } else {
            //this.processDebug();  
            this.responseBody = 'Resource ' + this.resourceName + ' unknown!';
            success = false;
        }
        return success;
    }

    /* *********************************************************************** */

    private void processDebug() {
        String body = '- resourceName: ' + this.resourceName + '\n';
        body += '- resourceId: ' + this.resourceId + '\n';
        body += '================\n';
        body += JSON.serializePretty(this.request);
        body += '================\n';
        body += '- Requested URI is ' + this.request.requestURI + '\n';
        body += '- Resource Path is ' + this.request.resourcePath + '\n';
        body += '- Method is ' + this.request.httpMethod + '\n';
        if (this.request.requestBody != null) {
            body += '- Body:\n' + this.request.requestBody.toString() + '\n';
        }
        body += '================\n';
        body += 'Params:\n';
        for (String keyp : this.params.keySet()) {
            body += '- ' + keyp + ': ' + this.params.get(keyp) + '\n';
        }
        body += '================\n';
        body += 'Headers:\n';
        Map<string, String> headers = this.request.headers;
        for (String key : headers.keySet()) {
            body += '- ' + key + ': ' + headers.get(key) + '\n';
        }

        this.statusCode = 200;
        this.responseBody = body;    
    }
    

    /*private void extractUriParts() {
        this.resourceId = URLCommons.getURLId(this.request.requestURI);
        this.params = URLCommons.convertKeysToLowerCase(this.request.params);
        this.resourceName = this.request.requestURI.toLowerCase().remove(this.baseUri).trim();
        if (String.isNotBlank(this.resourceId)) {
            this.resourceName = this.resourceName.remove(this.resourceId.toLowerCase());
        }
        this.resourceName = this.resourceName.removeEnd('/');
    }   */

    private void extractUriParts() {

        this.params = URLCommons.convertKeysToLowerCase(this.request.params);

        // Normalize URI first (avoid trailing-slash edge cases)
        String uri = this.request.requestURI != null ? this.request.requestURI.toLowerCase().trim() : '';
        uri = uri.removeEnd('/');

        // Part after /openapi/v2/
        String rest = uri.remove(this.baseUri).trim();

        // If there is no "/" in the remaining path, there is NO resourceId.
        // Example: "payment-gateway-capture"  -> resourceName only
        // Example: "claim/001122"             -> resourceName + resourceId
        if (!rest.contains('/')) {
            this.resourceName = rest;
            this.resourceId = null;
            return;
        }

        // There is an ID: resourceName is the first segment, resourceId is the last segment
        List<String> parts = rest.split('/');
        this.resourceName = parts.size() > 0 ? parts[0] : null;
        this.resourceId = parts.size() > 1 ? parts[parts.size() - 1] : null;
    }


}