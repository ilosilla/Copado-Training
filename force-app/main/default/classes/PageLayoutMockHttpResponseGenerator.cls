@isTest global class PageLayoutMockHttpResponseGenerator implements HttpCalloutMock{

     // Mock para la clase Account_ControllerTest, sirve para probar la llamada a tooling api
    global HTTPResponse respond(HTTPRequest req) {
        // Status y Headers no son relevantes.
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        
        if (req.getMethod().equals('GET') == true){
            // Respuesta falsa que devuelve siempre el nombre "LayoutForTesting-Edition Layout"
            // que corresponde al layout del mismo nombre para Account.
            res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ProfileLayout","records":[{"attributes":{"type":"ProfileLayout","url":"/services/data/v41.0/tooling/sobjects/ProfileLayout/01G1r00005wUeB9EAK"},"Layout":{"attributes":{"type":"Layout","url":"/services/data/v41.0/tooling/sobjects/Layout/00h1w000000MmJiAAK"},"Name":"LayoutForTesting-Edition Layout"}}]}');
        }
        
        System.debug('MOCK res=> ' +res);
       
        return res;
    }

}