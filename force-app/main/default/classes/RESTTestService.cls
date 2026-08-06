/**
 * @author         Ramón Prades
 * @date           November 2023
 * @description    Web service te test connectivity from other systems
*/
@RestResource(urlMapping='/openapi/v1/test-service/*')
global class RESTTestService {

    @HttpGet 
    global static void get() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;  
        String body = buildBody(req);
        res.statusCode = 200;            
        res.responseBody = Blob.valueOf(body);
    }

    @HttpPost
    global static void post() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;  
        String body = buildBody(req);
        res.statusCode = 200;            
        res.responseBody = Blob.valueOf(body);
    }

    private static String buildBody(RestRequest req) {
        String body = '- Requested URI is ' + req.requestURI + '\n';
        body += '- Resource Path is ' + req.resourcePath + '\n';
        body += '- Method is ' + req.httpMethod + '\n';
        if (req.requestBody != null) {
            body += '- Body:\n' + req.requestBody.toString() + '\n';
        }
        body += '================\n';
        body += 'Params:\n';
        Map<string, String> params = req.params;
        for (String keyp : params.keySet()) {
            body += '- ' + keyp + ': ' + params.get(keyp) + '\n';
        }
        body += '================\n';
        body += 'Headers:\n';
        Map<string, String> headers = req.headers;
        for (String key : headers.keySet()) {
            body += '- ' + key + ': ' + headers.get(key) + '\n';
        }
        return body;
    }

}