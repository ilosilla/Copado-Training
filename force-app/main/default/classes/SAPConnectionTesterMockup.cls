/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Commons
* @description 	Mockup callout to test SAPConnectionTester
*/
@isTest global class SAPConnectionTesterMockup implements HttpCalloutMock {
    global Boolean alive = true;
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token', 'x111ds');
        res.setHeader('set-cookie', 'x111ds');
        res.setBody('{"example":"test"}');
        if (this.alive) {
            res.setStatusCode(200);
        } else {
            res.setStatusCode(500);
        }
        return res;
    }
}