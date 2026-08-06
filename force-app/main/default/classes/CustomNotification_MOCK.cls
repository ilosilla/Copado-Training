/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			16-09-2019
Description:    Mock Response Generator para la clase CustomNotification
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/
@isTest
global class CustomNotification_MOCK implements HttpCalloutMock{
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        System.debug('Body: ' + req.getBody());
        
        // Optionally, only send a mock response for a specific endpoint and method.
        HttpResponse res = new HttpResponse();
		res.setStatusCode(200);
        String jsonResponse = '{"size" : 1,"totalSize" : 1,"done" : true,"queryLocator" : null,"entityTypeName" : "CustomNotificationType","records" : [ {"attributes" : { "type" : "CustomNotificationType","url" : "/services/data/v46.0/tooling/sobjects/CustomNotificationType/0ML1w0000004CC2GAM"}, "Id" : "0ML1w0000004CC2GAM", "CustomNotifTypeName" : "SAP Automations Custom Notification"} ]}';
        res.setBody(jsonResponse);
        
        System.debug('MOCK res=> ' +res);
        
        return res;
    }
}