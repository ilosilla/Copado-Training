/**
* @author 		Ramón Prades
* @date 		Martch 2023
* @group 		Prices
* @description 	Clears pricebooks by deactivating entries no longer valid in SAP
*/

global class BatchPriceCleaner implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    Pricebook2 pricebook;
    private final String logScenario = 'SAP-PRICES-CLEAN';
    private SystemLog logger;
    private Boolean useSpecialPrices;
    private Integer numInactive;
    private Integer numDeleted;
    private Integer numErrors;

    /**
     * executeInBatch
     * 
     * Para limpiar todos los price books
     */
    global static void executeInBatch() {
        List<Pricebook2> priceBooks = new PricebooksSelector().selectBySapSync();
        for (Pricebook2 pBook : priceBooks) {
            Database.executeBatch(new BatchPriceCleaner(pBook.Id));                
        }
    } // executeInBatch

    /**
     * executeInBatch
     * 
     * Para limpiar un price book
     */
    global static void executeInBatch(Id pricebookId) {
        Database.executeBatch(new BatchPriceCleaner(pricebookId));                
    } // executeInBatch


    /**
     * Constructor
     * 
     * Id del pricebook a limpiar
     */
    global BatchPriceCleaner(Id pricebookId) {        
        this.pricebook = new PricebooksSelector().selectById(new Set<Id>{pricebookId})[0];
        this.logger = new SystemLog(this.logScenario);
        Boolean isCleanable = (this.pricebook.IsActive && this.pricebook.SAPSync__c);
        this.useSpecialPrices = (this.pricebook.SAPCustomer__c != null && this.pricebook.SAPCustomer__c > 0);
        this.logger.addInfo('Cleaning price book ' + this.pricebook.Name);
        this.logger.addInfo('*************************');
        this.logger.addInfo('Is Cleanable? ' + isCleanable);
        this.logger.addInfo('Use Special Prices? ' + this.useSpecialPrices);
        this.numInactive = 0;
        this.numDeleted = 0;
        this.numErrors = 0;
        if (!isCleanable) {
            this.logger.saveLog();
            throw new ContextException('Pricebook not cleanable');
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Select all PricebookEntry records
        return Database.getQueryLocator('SELECT Id, isActive, ProductCode FROM PricebookEntry where Pricebook2Id = \'' + this.pricebook.Id + '\' and isActive = true');
    } // start

    global void execute(System.SchedulableContext context) {
        BatchPriceCleaner.executeInBatch();
    } 
    
    global void execute(Database.BatchableContext bc, List<sObject> scope) {   
        
        this.logger.addInfo('Entrando en el execute de ' + this.pricebook.Name + ' con ' + scope.size() + ' records');

        // Deactivate entries (isActive = false)
        List<PricebookEntry> entriesToUpdate = this.cleanEntries((List<PricebookEntry>) scope);    
        List<Id> idsToDelete = new List<Id>();    
        Database.SaveResult[] srList = Database.update(entriesToUpdate, false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                this.numInactive++;
                idsToDelete.add(sr.getId());
            } else {
                this.numErrors++;
            }
        }

        // And delete as much as possible
        Database.DeleteResult[] drList = Database.delete(idsToDelete, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                this.numDeleted++;
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Do any post-processing here
        this.logger.addInfo('> Registros desactivados ' + this.numInactive);        
        this.logger.addInfo('> Registros borrados ' + this.numDeleted);
        this.logger.addInfo('> Errors al actualizar ' + this.numErrors);
        this.logger.saveLog();
    }

    /*
     * PRIVATE METHODS 
     */

    private List<PricebookEntry> cleanEntries(List<PricebookEntry> entries) {        
        Set<String> codes = new Set<String>();
        for (PricebookEntry entry : entries) {
            if (!codes.contains(entry.ProductCode)) {
                codes.add(entry.ProductCode);
            }
        }
        Set<String> sapCodes;
        if (this.useSpecialPrices) {
            sapCodes = this.readSAPSpecialCodes(codes);
        } else {
            sapCodes = this.readSAPCodes(codes);
        }        
        List<PricebookEntry> inactives = new List<PricebookEntry>();
        for (PricebookEntry entry : entries) {
            if (!sapCodes.contains(entry.ProductCode)) {
                entry.isActive = false;
                inactives.add(entry);
            }
        }
        return inactives;
    }

    private Set<String> readSAPCodes(Set<String> codes) {
        Set<String> sapCodes = new Set<String>();
        List<ZB2B_PRICE1__x> sapPrices = [select Material__c from ZB2B_PRICE1__x where Bzirk__c = :this.pricebook.Bzirk__c and Material__c in :codes];
        for (ZB2B_PRICE1__x sapPrice : sapPrices) {
            if (!sapCodes.contains(sapPrice.Material__c)) {
                sapCodes.add(sapPrice.Material__c);
            }
        }
        return sapCodes;
    }

    private Set<String> readSAPSpecialCodes(Set<String> codes) {
        Set<String> sapCodes = new Set<String>();
        String customer = String.valueOf(this.pricebook.SAPCustomer__c);
        List<ZB2B_PRICE2__x> sapPrices = [select Material__c from ZB2B_PRICE2__x where Cliente__c = :customer and Material__c in :codes];
        for (ZB2B_PRICE2__x sapPrice : sapPrices) {
            if (!sapCodes.contains(sapPrice.Material__c)) {
                sapCodes.add(sapPrice.Material__c);
            }
        }
        return sapCodes;
    }

    
    private Boolean checkPriceIsActive(PricebookEntry entry) {
        // Implement your logic here to check if the PricebookEntry is active
        // Return true if the entry is active, false if it should be deleted
        return true;
    }

}