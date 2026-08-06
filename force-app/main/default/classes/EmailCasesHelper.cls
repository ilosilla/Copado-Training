/**
 * @author         Ramón Prades
 * @date           September 2024
 * @layer          Helper
 * @description    Utility methods to assist in identifying and working with emails retaled to cases
*/
public class EmailCasesHelper {

    private static final String CLAIM_FACTORY_FORM_ID = '%form-id:[CLAIM_FACTORY_INQUIRY]%';
    private static final Integer MAX_LENGTH = 131000;
    private static List<EmailServicesAddress> serviceAddresses = null;    

    /**
     * This method parses the subject line of an email message to identify a valid case number. 
     * If a valid case number is found, it is assigned to the email message in the parent and relatedTo attributes
     */
    public static void assignCasesToMessages(EmailMessage[] messages) {
        // Check if the mail is sent to ione of the service emails to prevent duplicates
        Map<String, Id> casesMap = getCasesMap(messages);
        if (casesMap.size() > 0) {
            for (EmailMessage message : messages) {
                if (message.RelatedToId == null) { //}) && !hasEmailServiceAddress(message)) {
                    String caseNumber = parseCaseNumber(message.Subject);
                    if (casesMap.containsKey(caseNumber)) {
                        Id caseId = casesMap.get(caseNumber);
                        message.ParentId = caseId;
                        message.RelatedToId = caseId;
                    }
                }
            }
        }
    }

    /**
     * Creates an EmailMessage based on an inbound message and a parent ID.
     */
    public static EmailMessage createIncomingEmailMessage(Messaging.InboundEmail inbound) {
        EmailMessage msg = null;
        // Process only replies to messages sent from the app
        if (inbound.references != null || inbound.inReplyTo != null ) {
            Case relatedCase = findRelatedCase(inbound);
            if (relatedCase != null) {
                msg = new EmailMessage();
                msg.Incoming = true;
                msg.Status = '1';       // Read
                msg.FromAddress = inbound.fromAddress;
                msg.ToAddress = String.join(inbound.toAddresses, ',');
                msg.Subject = inbound.subject;
                msg.HtmlBody = trimToMaxLength(inbound.htmlBody);
                msg.TextBody = trimToMaxLength(inbound.plainTextBody);
                msg.ParentId = relatedCase.Id;
                msg.RelatedToId = relatedCase.Id;
                msg.MessageDate = System.now();
                EmailMessage[] replied = [select Id from EmailMessage where MessageIdentifier = :inbound.inReplyTo];
                if (replied.size() > 0) {
                    msg.ReplyToEmailMessageId = replied[0].Id;
                }
                insert msg;
                if (isClaimInquiry(inbound?.htmlBody ?? '')) {
                    String txt = msg.TextBody;
                    if (String.isBlank(txt)) {
                        txt = msg.HtmlBody;
                    }                                    
                    SAPCasesService.updateCaseResponse(relatedCase, txt);
                }
            }
        } 
        return msg;
    }

    //==================================================================================================================

    private static String trimToMaxLength(String variable) {
        if (variable != null && variable.length() > MAX_LENGTH) {
            return variable.substring(0, MAX_LENGTH);
        }
        return variable;
    }

    /*
     * Checks if an email service address is in the list of recipiuents of the message
     */
    /*
    private static Boolean hasEmailServiceAddress(EmailMessage message) {
        Boolean isEmailServiceAddress = false;
        String recipients = message.ToAddress;
        if (String.isNotBlank(message.CcAddress)) {
            recipients += ',' + message.CcAddress;
        }
        if (String.isNotBlank(message.BccAddress)) {
            recipients += ',' + message.BccAddress;
        }
        if (EmailCasesHelper.serviceAddresses == null) {
            EmailCasesHelper.serviceAddresses = [SELECT LocalPart, EmailDomainName FROM EmailServicesAddress WHERE IsActive = true];            
        }
        for (EmailServicesAddress service : EmailCasesHelper.serviceAddresses) {
            String serviceEmailAddress = service.LocalPart + '@' + service.EmailDomainName;
            if (recipients.contains(serviceEmailAddress)) {
                isEmailServiceAddress = true;
                break;
            }
        }
        return isEmailServiceAddress;
    }
    */

    /*
     * Searches an inbound message for a related case.
     */
    private static Case findRelatedCase(Messaging.InboundEmail inbound) {

        Case[] cases = new List<Case>();

        // First try the MessageIdentifier
        if (inbound.inReplyTo != null) {
            EmailMessage[] emails = [select Id, MessageIdentifier, RelatedToId from EmailMessage where MessageIdentifier = :inbound.inReplyTo];
            if (emails.size() > 0) {
                Id caseId =emails[0].RelatedToId;
                if (caseId != null) {
                    cases = new CasesSelector().selectById(new Set<Id>{ caseId });                    
                }
            } 
        }     
        
        // Second, try the subject
        if (cases.size() == 0) {
            String caseNumber = parseCaseNumber(inbound.subject);
            if (caseNumber != null) {
                cases = new CasesSelector().selectByCaseNumbers(new Set<String>{caseNumber});
            }
        }

        if (cases.size() > 0) {
            return cases[0];
        } else {
            return null;
        }

    }


    /*
     * Gets a Map of caseNumbers and case objects
     */
    private static Map<String, Id> getCasesMap(List<EmailMessage> messages) {
        Set<String> caseNumbers = new Set<String>();
        for (EmailMessage message :messages) {
            if (message.RelatedToId == null) {
                String caseNumber = parseCaseNumber(message.Subject);
                if (!caseNumbers.contains(caseNumber)) {
                    caseNumbers.add(caseNumber);
                }
            }
        }
        return readCases(caseNumbers);
    }

    /*
     * Retrieves cases corresponding to the specified case numbers
     */
    private static Map<String, Id> readCases(Set<String> caseNumbers) {
        Map<String, Id> cases = new Map<String, Id>();
        for (Case c : [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN :caseNumbers]) { 
            cases.put(c.CaseNumber, c.Id);
        }
        return cases;
    }
        
    /*
     * Tries to get a case number from the email subject
     */
    private static String parseCaseNumber(String text) {
        String matchedNumber = null;
        String patternStr = '\\s+([0-9]{6,10})'; // 6 to 10 numbers
        Pattern p = Pattern.compile(patternStr);
        Matcher matcher = p.matcher(text?.toLowerCase());

        // Check if the pattern is found in the text        
        if (matcher.find()) {
            matchedNumber = matcher.group(1); 
        }

        return matchedNumber;

    } // parseCaseNumber

    /*
     * Mira si es el factory inquiry
     */ 
    private static Boolean isClaimInquiry(String text) {
        return text?.containsIgnoreCase(CLAIM_FACTORY_FORM_ID);
    }

}