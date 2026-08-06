@isTest (seeAllData=true)
public class WebhooksServiceTest{
 
    static testmethod void testPublish(){
        Test.setMock(HttpCalloutMock.class, new mockCallout());
        WebhooksList__c wh = new WebhooksList__c();
        wh.Name = 'TEST_WEBHOOK';
        wh.url__c = 'http://test.com';
        wh.isActive__c = true;
        insert wh;

        Boolean result = WebhooksService.publish('TEST_WEBHOOK', 'This is the title', 'This is the body');
        System.assertEquals(true, result, 'The publish should have been true');

        result = WebhooksService.publish('XXXXXX', 'This is the title', 'This is the body');
        System.assertEquals(false, result, 'The publish should have been false');

    }
    
    public class mockCallout implements HttpCalloutMock
    {
        public HttpResponse respond(HttpRequest request)
        {
            HttpResponse res = new HttpResponse();
            res.setBody( '{"text":"value"}');
            res.setStatusCode(200);
            return res;
        }   
    }
}