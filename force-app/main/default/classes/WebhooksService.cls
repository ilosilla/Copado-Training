/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		Commons
* @description 	Class to write a message to an external webhook and to write
*/
public class WebhooksService {

    /**
     * Writes a message to the specified webhook
     */
    public static Boolean publish(String name, String title, String body) {
        Boolean success = false;
        WebhooksList__c webhook = WebhooksList__c.getValues(name);
        if (webhook != null) {
            if (webhook.isActive__c) {
                String message = buildTeamsMessage(title, body);
                System.enqueueJob(new CallOut(webhook.url__c, 'POST', message));
                success = true;
            }
        }
        return success;
    } // publish

    /**
     * Builds the mesasge to send to a Microsoft Teams webhook.
     * The boddy accepts markup as in [text](url) for hyperlinks
     */
    private static String buildTeamsMessage(String title, String body) {
        String message = '{"type":"message","attachments":[{"contentType":"application/vnd.microsoft.card.adaptive",'
            + '"contentUrl":null,"content":{"$schema":"http://adaptivecards.io/schemas/adaptive-card.json",'
            + '"type":"AdaptiveCard","version":"1.2","body":[{"type": "TextBlock","text": "%%text%%"}]}}]}';
        String text = body;
        if (String.isNotBlank(title)) {
            text = '**' + title + '**\\r\\n' + '\n' + text;
        }
        message = message.replace('%%text%%', text);
        return message;
    } // buildTeamsMessage

    public class CallOut implements System.Queueable, Database.AllowsCallouts {
         
        private final String url;
        private final String method;
        private final String body;
         
        public CallOut(String url, String method, String body) {
            this.url = url;
            this.method = method;
            this.body = body;
        }
         
        public void execute(System.QueueableContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(method);
            req.setBody(body);
            Http http = new Http();
            HttpResponse res = http.send(req);
        }
    } // inner class

} // class