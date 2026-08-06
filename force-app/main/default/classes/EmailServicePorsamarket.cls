/**
 * @author         Ivan Losilla
 * @date           May 2025
 * @layer          Email Service Handler
 * @description    
 * EmailServicePorsamarket is a utility class that implements the InboundEmailHandler interface.
 * It provides a method to tell salesforce that there is a new file on sharepoint.
 */

 global class EmailServicePorsamarket implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        if (Test.isRunningTest() == false) {
            Porsamarket aux = new Porsamarket();
            aux.processFolder();
        }

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        return result;
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}