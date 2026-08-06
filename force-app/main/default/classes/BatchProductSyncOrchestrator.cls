/**
 * @name        BatchProductSyncOrchestrator
 * @author      Ramón Prades
 * @date        April 2026
 * @group       SAP Integration - Products
 * @description 
 *      Wrapper batch that orchestrates product sync and runs pre-sync operations (like backoffice sync) in a safe transaction scope.
 *      Delegates the actual product synchronization to BatchProductSyncProcessor.
 */

 public class BatchProductSyncOrchestrator implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private Boolean fullMode = false;
    private Integer daysBack = 0;
    private Boolean runPricebookUpdate = false;
    private Boolean runB2BSync = false;
    private Boolean forceActive = false;
    private SystemLog logger;
    private String[] skuFilter = new List<String>();

    // ---------------------- STATIC RUNNERS ---------------------------
    public static void executeFullModeBatch() {
        BatchProductSyncOrchestrator processor = new BatchProductSyncOrchestrator();
        processor.setFullMode(true);
        processor.setForceActive(true);
        processor.setRunPricebookUpdate(false);
        Database.executeBatch(processor);        
    }

    public static void executeWithFilterBatch(List<String> skus) {
        BatchProductSyncOrchestrator processor = new BatchProductSyncOrchestrator();
        processor.setFullMode(false);
        processor.setForceActive(false);
        processor.setRunPricebookUpdate(true);
        processor.setSKUFilter(skus);
        Database.executeBatch(processor);        
    }


    public static void executeFullPricesBatch() {
        BatchProductSyncOrchestrator processor = new BatchProductSyncOrchestrator();
        processor.setFullMode(true);
        processor.setForceActive(true);
        processor.setRunPricebookUpdate(true);
        Database.executeBatch(processor);        
    }

    public static void executeDailyBatch() {
        BatchProductSyncOrchestrator processor = new BatchProductSyncOrchestrator();
        processor.setFullMode(false);
        processor.setRunPricebookUpdate(true);
        Database.executeBatch(processor);
    }

    public static void executeDailyWithB2BBatch() {
        BatchProductSyncOrchestrator processor = new BatchProductSyncOrchestrator();
        processor.setFullMode(false);
        processor.setRunPricebookUpdate(true);
        processor.setRunB2BSync(true);
        Database.executeBatch(processor);
    }

    // --------------------- CONSTRUCTORS ------------------------------
    public BatchProductSyncOrchestrator() {
        this.logger = new SystemLog('PRODUCT-SYNC');
        this.logger.setSummary('Product Sync Orchestrator');
        this.logger.setTag('Orchestrator');
        this.logger.addInfo('Starting product sync orchestrator');
        this.logger.saveLog();
    }
    
    // ------------------- CONFIGURATION SETTERS -----------------------
    public void setFullMode(Boolean value) {
        this.fullMode = value;
    }

    public void setDaysBack(Integer value) {
        this.daysBack = value;
    }

    public void setRunPricebookUpdate(Boolean value) {
        this.runPricebookUpdate = value;
    }

    public void setRunB2BSync(Boolean value) {
        this.runB2BSync = value;
    }

    public void setForceActive(Boolean value) {
        this.forceActive = value;
    }

    public void setSKUFilter(String[] skus) {
        this.skuFilter = skus;
    }

    // ----------------------- BATCH METHODS ----------------------------

    public void execute(SchedulableContext sc) {
        this.setFullMode(false);
        this.setRunPricebookUpdate(true);
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
    }

    public void execute(Database.BatchableContext context, List<User> scope) {              
        this.logger.addInfo('Running pre-sync operations');
        try {
            MasterProductBackofficeSync syncer = new MasterProductBackofficeSync();
            Integer records = syncer.sync();
            this.logger.addInfo('Backoffice synced records: ' + records);
        } catch (Exception ex) {
            this.logger.addError('Error during backoffice sync');
            this.logger.addError(ex);
        }
    }

    public void finish(Database.BatchableContext context) {
        this.logger.saveLog();
        BatchProductSyncProcessor processor = new BatchProductSyncProcessor();
        if (this.fullMode) {
            processor.setFullMode(this.fullMode);
        } else {
            processor.setDaysBack(this.daysBack);    
            processor.setSKUFilter(this.skuFilter);
        }
        processor.setRunPricebookUpdate(this.runPricebookUpdate);
        processor.setRunB2BSync(this.runB2BSync);
        processor.setLogger(this.logger);
        processor.setForceActive(this.forceActive);
        Database.executeBatch(processor, 200);
    }
}