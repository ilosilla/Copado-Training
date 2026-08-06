/**
* @author 		Ivan Losilla
* @date 		September 2024
* @group 		SAP
* @description 	Sends all the info of the Accounts set Dirty__c as true, to SAP to sync the values. 
*               IMPORTANT: If manually called, it should be called with a batch of 1.
*
*               SAPAccountSync batchJob = new SAPAccountSync();
*               Database.executeBatch(batchJob, 1);
*/
global class SAPAccountSync implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{

    private final String logScenario = 'SAP_ACCOUNT_SYNC';
    private SystemLog logger;
    private Map<String, String> errorMessages = new Map<String, String>();
    private Map<String, Account> errorAccounts = new Map<String, Account>();
    private Map<String, Account> successAccounts = new Map<String, Account>();
    global Integer recordsProcessed = 0;
    global Integer recordsUpdated = 0;

    global SAPAccountSync() {     
        this.logger = new SystemLog(this.logScenario);
        this.logger.addInfo('Clase creada en constructor');
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, name, sap_Id__c FROM Account WHERE Dirty__c = true'+(Test.isRunningTest()?' LIMIT 1':''); 
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext context){
        Database.executeBatch(new SAPAccountSync(), 1);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            this.recordsProcessed++;
            AccountTransactionHandler.TransactionResponse result = Account_Controller.saveAccount('{}', acc.Id, true);
            if (result.success == false) {
                errorMessages.put(acc.Id, result.errorMessage);
                errorAccounts.put(acc.Id, acc);
            } else {
                successAccounts.put(acc.Id, acc);
                this.recordsUpdated++;
            }
        }
    }
    
    global void finish(Database.BatchableContext bc){
        this.logSync();
    }

    private void logSync() {
        for (String accountIdError : this.errorMessages.keySet()) {
            Account acc = this.errorAccounts.get(accountIdError);
            String message = this.errorMessages.get(accountIdError);
            this.logger.addError(acc.Id + ' - ' + acc.name + ' (' + acc.sap_Id__c + '): ' + message );
        }
        this.logger.saveLog(true);
    }
}