/**
* @author 			Ivan Losilla
* @date 			November-2022
* @group 			Mailchimp
* @description 	    Manage the queue of mocks https://salesforce.stackexchange.com/questions/105322/callout-mock-responses-multiple-http-status-code-values
*/

@isTest
public class QueueHttpMock implements HttpCalloutMock {
    HttpResponse[] responses = new HttpResponse[0];
    public void addResponse(HttpResponse response) {
        responses.add(response);
    }
    public HttpResponse respond(HttpRequest request) {
        return responses.remove(0);
    }
}