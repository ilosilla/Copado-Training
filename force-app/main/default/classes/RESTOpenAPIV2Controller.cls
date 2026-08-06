/**
 * @author         Ramón Prades
 * @date           September 2024
 * @description    REST OpenAPI V2 controller (no auth required)
 * 
 * This controller processes URLs in the following format:
 * 
 * /openapi/v2/<resource-name>/[<resource-id>][?params]
 * 
 * Example:
 * 
 * /openapi/v2/claim/001122?approvedBy=112233
 * 
 * In this example, 'claim' is the resource name, '001122' is the optional resource ID, 
 * and 'approvedBy=112233' is an example of an optional query parameter.
 * 
 */
@RestResource(urlMapping='/openapi/v2/*')
global class RESTOpenAPIV2Controller {

    @HttpGet 
    global static void doGet() {
        // Use a GET because this is going to be invoed from a link in an email
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;        
        RESTOpenAPIV2Helper helper = new RESTOpenAPIV2Helper(request, 'GET');        
        helper.processResource();
        response.statusCode = helper.statusCode;
        if (String.isNotBlank(helper.responseBody)) {
            if (String.isNotBlank(helper.contentType)) {
                response.addHeader('Content-Type', helper.contentType);
            } 
            response.responseBody = Blob.valueOf(helper.responseBody);
            response.statusCode = helper.statusCode > 0 ? helper.statusCode : 200; // Si el helper no ha establecido un status code específico, devolvemos 200 OK
        }
    }

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        RESTOpenAPIV2Helper helper = new RESTOpenAPIV2Helper(req, 'POST');        
        if (helper.resourceName?.toLowerCase() == 'debug') {
            helper.processResource();
            res.statusCode = helper.statusCode;
            if (String.isNotBlank(helper.responseBody)) {
                res.responseBody = BLob.valueOf(helper.responseBody);
            }
        } else if (helper.resourceName?.toLowerCase() == 'echo') {
            // Respondemos con el body recibido (sin procesar)
            String body = req.requestBody != null ? req.requestBody.toString() : null;
            body += '\n*****************************************+\n';
            for (String key : req.headers.keySet()) {
                body += key + ' → ' + req.headers.get(key) + '\n';
            }
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(
                '{"received":' + (body != null ? body : 'null') + '}'
            );
        } else if (helper.resourceName?.toLowerCase() == 'payment-gateway-capture') {
            res.statusCode = B2B_PaymentGatewayCapture.handle(req);
        } else if (helper.resourceName?.toLowerCase() == 'payment-gateway-response') {
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(B2B_PaymentGatewayCapture.responsePage(req));
            res.addHeader('Content-Type', 'text/html; charset=UTF-8');
        } else if (helper.resourceName?.toLowerCase() == 'payment-gateway-error') {
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(B2B_PaymentGatewayCapture.errorPage(req));
            res.addHeader('Content-Type', 'text/html; charset=UTF-8');
        } else {
            // No hace echo: puedes poner lo que quieras aquí (por ejemplo, 204 No Content)
            res.statusCode = 501;
            res.responseBody = Blob.valueOf('Es --> ' + helper.resourceName);
        }
    }
    
}