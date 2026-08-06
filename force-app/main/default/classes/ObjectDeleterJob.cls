/**
 * @author         Ramón Prades
 * @date           January 2025
 * @layer          Tools
 * @description    Deletes all rows matching a condition in any given object
*/
global class ObjectDeleterJob  implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private String objectName;
    private String condition;
    private Boolean isTest = true;
    private SystemLog logger;
    private final String scenario = 'MAIL';
    private Integer nRecords = 0;

    global ObjectDeleterJob(String objectName) {
        this.objectName = objectName;
        this.logger = new SystemLog(this.scenario);
        this.logger.setTag(this.objectName);
        this.nRecords = 0;
    }

    global void setCondition(String condition) {
        this.logger.addDebug('Condition set to: ' + condition);
        this.condition = condition;
    }

    global void setTest(Boolean value) {
        this.logger.addDebug('isTest set to: ' + value);
        this.isTest = value;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.buildQuery());
    }

    global void execute(System.SchedulableContext context) {
        Database.executeBatch(this);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            this.processRecords(scope);
        } catch(Exception ex) {
            this.logger.addError(ex);
            this.logger.saveLog();
        }
    }

    private void processRecords(List<SObject> records) {
        this.nRecords += records.size();
        if (!this.isTest) {
            delete records;
        }
    }

    global void finish(Database.BatchableContext bc) {
        this.logger.addDebug('Records processed: ' + this.nRecords);
        this.logger.saveLog(true);
    }

    private String buildQuery() {
        if (String.isBlank(condition)) {
            this.condition = 'Id = null'; // Is the condition is blank, don't return any rows
        }
        return 'select Id from ' + this.objectName + ' where ' + this.condition;
    }

}