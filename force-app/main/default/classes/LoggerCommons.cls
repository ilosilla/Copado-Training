/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Commons
* @description 	Common methods for logging events
*/
public class LoggerCommons {

    /**
     * Logs an exception
     */
    public static String LogException(String scenario, String processId, Exception ex) {
        String newLine = '\n';
        Logger.setScenario(scenario);  
        String text = 'Message: ' + ex.getMessage() + newLine;
        text += 'Exception: ' + ex.getTypeName() + ' received processing ' + processId + newLine;
        text += ex.getStackTraceString() + newLine;
        if (ex.getTypeName().equalsIgnoreCase('DMLException')) {
            for (Integer i = 0; i < ex.getNumDml(); i++) {
                text += '[' + ex.getDmlFieldNames(i) + '] ' + ex.getDmlMessage(i) + newLine;
            }
        }
        Logger.error(text);
        Logger.saveLog();
        return Logger.getTransactionId();
    }

    /**
     * Creates a case from an exception
     */
    public static void createCase(Exception ex) {
        String Id;
        try {
            String subject = LoggerCommons.getIssueSubject(ex);
            String description = ex.getTypeName() + ': ' + ex.getMessage() + '\n\n';
            description += ex.getTypeName() + ex.getStackTraceString() + '\n\n';
            if (ex.getTypeName().equalsIgnoreCase('DMLException')) {
                for (Integer i = 0; i < ex.getNumDml(); i++) {
                    description += '[' + ex.getDmlFieldNames(i) + '] ' + ex.getDmlMessage(i) + '\n';
                }
            }
            LoggerCommons.insertCase(subject, description);
        } catch(Exception iex) {
            LoggerCommons.LogException('CREATE_CASE', 'Case', iex);
        }
    } // createCase

    @future private static void insertCase(String subject, String description) {
        Case itCase = new Case();
        //itCase.RecordTypeId = RecordTypeLibrary.Case_ItCase;
        itCase.Subject = subject;
        itCase.Description = description;
        itCase.SuppliedEmail = UserInfo.getUserEmail();
        itCase.SuppliedName = UserInfo.getName();
        itCase.suppliedCompany = UserInfo.getOrganizationName();
        //insert itCase;
    }

    private static String getIssueSubject(Exception ex) {
        String subject = '';
        String[] lines = ex.getStackTraceString().split('\n');
        if (lines.size() > 0) {
            subject = lines[1].replace('Class.', '');
            subject = subject.substringBefore('.') + ': ';
        }
        subject += ex.getMessage();
        return subject;
    }
} // class