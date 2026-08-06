/**
 * @author         Ramón Prades
 * @date           February 2025
 * @layer          Services
 * @description    description
 * 
 * * Purpose:
 * ---------
 * This class processes emails related to cases and applies AI to generate summaries. 
 * It extracts relevant details from incoming emails, interacts with an AI engine 
 * (via SAP CPI) to summarize conversations, and provides structured insights 
 * that can be used for case management.
 * 
 * Features:
 * ---------
 * - Parses case-related emails to extract key information.
 * - Calls an AI service through SAP CPI to generate a concise summary.
 * - Identifies whether the case conversation is resolved or requires further action.
 * - Returns a structured output that can be used for case updates or automation.
 * 
 * Usage:
 * -------
 * CaseEmailSummarizer summarizer = new CaseEmailSummarizer();
 * String summary = summarizer.processEmail(emailBody);
 * System.debug(summary);
 * 
 */
public class CaseEmailSummarizer {

    public static final String CLAIM_FACTORY_FORM_ID = '%form-id:[CLAIM_FACTORY_INQUIRY]%';

    private static final String EMAIL_SUMMARY_PROMPT = 
        'You are an AI assistant that summarizes emails concisely, focusing only on key details. ' +
        'Ignore greetings, sign-offs, and external warnings. Extract the core message in a brief sentence. ' +
        'If technical details or product codes are mentioned, include them. ' +
        'Translate the final summary to language {0}.\n\n';
        
    private static final String FACTORY_SUMMARY_PROMPT = 'CLAIM-FACTORY-SUMMARY';
    /*
        'You are an AI assistant that extracts key details from case-related emails in structured HTML format within a <div>. ' +
        'For each email, include:\n' +
        '- Sender, recipient, and date.\n' +
        '- A concise summary focused on the claim, avoiding salutations and irrelevant details. Include product codes when mentioned.\n\n' +
    
        'At the end, add a conversation status section:\n' +
        '- If the last email confirms resolution, set status to "Closed."\n' +
        '- If any action or question remains unanswered, set status to "Open," specifying who must act and what they must do.\n\n' +
    
        'Ensure output is clear, concise, and in proper HTML format. No quotes or extra text.\n\n' +
    
        'Use this pattern for each email:\n' +
        '<div class="ai-section {even}"><p><strong><a href="{messageLink}" target="_blank">Email #{number}</a></strong> | <strong>Date:</strong> {date} | <strong>From:</strong> sender ' +
        '| <strong>To:</strong> {toAddress} </p><p>{summary}</p></div>.\n' +
        'Add a class "even" to "ai-section" for emails where the position (starting from 1) is an even number (2, 4, 6, etc.). In the sender use the name. If the name is blank, use the email.' +
    
        'For the status:\n' +
        '<div class="conversation-status"><p><strong>Conversation Status</strong></p><p>{value returned for conversation status}</p></div>.\n\n' +
    
        'Translate all output to language {0}.';
        */
   /**
    * Summarizes all emails exchanged between the company and the factory regarding a claim.    
    */
    public String summarizeClaimFactoryEmails(Id caseId) {
        String result = null;
        AIPrompt__c prompt = new AIPromptsSelector().selectByDeveloperName(FACTORY_SUMMARY_PROMPT);
        List<String> messages = this.readFactoryEmails(caseId);
        if (messages.size() > 0) {
            AIService service = new AIService();
            service.setTemperature(prompt.Temperature__c );
            service.setModel(prompt.Model__c);
            if (prompt.Timeout__c > 0) {
                service.setTimeout(Integer.valueOf(prompt.Timeout__c));
            }
            service.setSystemRole(prompt?.SystemRole__c?.replace('{0}', UserInfo.getLanguage()));
            service.setUserRole(prompt?.UserRole__c?.replace('{0}', String.join(messages, '\n\n')));
            result = service.getResponse();
        }
        //Integer code = service.getStatusCode();
        return result;
    }

   /**
    * Summarizes an email
    */
    public String summarizeEmail(String mailBody) {
        AIService service = new AIService();
        service.setTemperature(0.5);
        service.setSystemRole(EMAIL_SUMMARY_PROMPT.replace('{0}', UserInfo.getLanguage()));
        service.setUserRole('This is email body: ' + mailBody + '\n\n');
        String result = service.getResponse();
        return result.replace('```html', '').replace('```', '');
    }

    // *************************************************************************************

    private List<String> readFactoryEmails(Id caseId) {
        
        List<String> factoryEmails = new List<String>();
        
        EmailMessage[] messages = [select Id, FromAddress, FromName, ToAddress, MessageDate, Subject, HtmlBody, TextBody 
                                        from EmailMessage       
                                        where parentId = :caseId 
                                        order by MessageDate];
        
        for (EmailMessage message : messages) {
            if (message.HtmlBody?.containsIgnoreCase(CLAIM_FACTORY_FORM_ID) || (message.Subject.containsIgnoreCase('Case') && message.Subject.containsIgnoreCase('(Claim Inquiry)'))) {
                String text = message.TextBody;
                if (String.isBlank(text)) {
                    text = message.HtmlBody;
                }
                String messageLink = SystemCommons.getObjectURL(message.Id);
                String entry = '** BEGIN OF MESSAGE ** MessageLink: {6}; FromAddress: {0}; FromName: {1}; ToAddress: {2}; MessageDate: {3}; Subject: {4}; MailBody: {5} ** END-OF-MESSAGE **';
                entry = entry.replace('{0}', message.FromAddress)
                            .replace('{1}', message?.FromName ?? '') 
                            .replace('{2}', message.ToAddress)
                            .replace('{3}', message.MessageDate.format())
                            .replace('{4}', message.Subject)
                            .replace('{5}', text)
                            .replace('{6}', messageLink);
                factoryEmails.add(entry);
            }
        }

        return factoryEmails;

    } // readFactoryEmails

}