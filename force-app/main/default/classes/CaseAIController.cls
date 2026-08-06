/**
 * @author         Ramón Prades
 * @date           February 2025
 * @layer          Controller
 * @description    Offers case-related AI servidces to LWC components
*/
public class CaseAIController {
    @AuraEnabled public static String summarizeFactoryEmails(Id caseId) {
        CaseEmailSummarizer summarizer = new CaseEmailSummarizer();
        return summarizer.summarizeClaimFactoryEmails(caseId);
    }
}