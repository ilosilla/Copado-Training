/**
 * @author         Ramón Prades
 * @date           March 2025
 * @layer          Platform Events
 * @description    Manages the PE sent by SAP when a customer is locked or unlocked
*/
public class PEVSAPAccountLockTriggerHandler {
    
    public static void afterInsert(List<SAP_Account_Lock__e> events) {
        SystemLog log = new SystemLog('SAP-EVENTS');
        log.setTag('SAP_Account_Lock');
        log.setInputObject(events);
        log.addInfo('Processing ' + events.size() + ' events of type SAP Account Lock');
        Boolean hasErrors = false;

        Account[] accounts = new List<Account>();
        for (SAP_Account_Lock__e e : events) {
            try {
                log.addInfo('==> Account ' + e.AccountId__c + ' - ' + e.SAPId__c + ': ' + e.IsLocked__c);
                Account acc = new Account();
                acc.Id = e.AccountId__c;
                acc.Is_Locked__c = e.IsLocked__c;
                accounts.add(acc);
            } catch (Exception ex) {
                hasErrors = true;
                log.addError('Inner Exception: ' + ex);
                e.addError('Error processing event: ' + ex.getMessage());
            }
        }
        
        Database.SaveResult[] results = Database.update(accounts, false);        
        for (Database.SaveResult res : results) {
            if (!res.isSuccess()) {
                hasErrors = true;
                log.addError('Error updating ' + res.getId());
                for (Database.Error err : res.getErrors()) {
                    log.addError('Error: ' + err.getMessage());
                }
            }
        }

        if (!hasErrors) {
            log.setSummary(events.size() +' account(s) updated successfully');
        } else {
            log.setSummary(events.size() +' account(s) updated with errors');
        }
        log.saveLog(true);
    }
}