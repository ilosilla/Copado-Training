/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			03-05-2019
Description:    Mock Response Generator para los test que involucran la clase Ficha360
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/
@isTest
global class Ficha360MockHttpResponseGenerator implements HttpCalloutMock{
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        System.debug('Body: ' + req.getBody());
        
        // Optionally, only send a mock response for a specific endpoint and method.
        HttpResponse res = new HttpResponse();
        
        // Para obtener los token y cookies necesarios al utilizar la clase SAPWS_Utility
        if ( req.getMethod().equals('GET') ){
            if(req.getEndpoint() == 'callout:SAP/api/customers/ping'){
                res.setHeader('x-csrf-token', 'token churro');
                res.setHeader('set-cookie', 'cookie churrito');
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
            } else if(req.getEndpoint().contains('/api/zcli/') ){
                res.setStatusCode(200);
                String jsonResponse = '"{\"balance_to_pay\":0,\"balance_to_refund\":0}"';
                res.setBody(jsonResponse);
            }
            
        }
        
        System.debug('MOCK res=> ' +res);
        
        return res;
    }
}