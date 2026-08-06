/**
 * @author         Ramón Prades
 * @date           September 2024
 * @layer          Email Service Handler
 * @description    
 * EmailServiceCases is a utility class that implements the InboundEmailHandler interface.
 * It provides a method to handle incoming emails and associates them to cases.
 */

global class EmailServiceCases implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        EmailCasesHelper.createIncomingEmailMessage(email);
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        return result;
    }

}