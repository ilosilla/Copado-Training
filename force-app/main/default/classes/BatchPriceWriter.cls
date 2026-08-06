/**
* @author 		Ramón Prades
* @date 		March 2023
* @group 		Commons
* @description  Upserts a list of price book entries.
*/
global class BatchPriceWriter implements Database.Stateful, Database.Batchable<List<sObject>> { 

    private final String logScenario = 'PRODUCTS&PRICES SYNC';
    private Pricebook2 pricebook;
    private List<PriceBookEntry> pbeList;
    private Integer numPage = 0;
    private SystemLog logger;
    private Integer newRecords = 0;
    private Integer updatedRecords = 0;
    private Integer numErrors = 0;
    private Integer numExceptions = 0;
    private List<String> errorMessages;

    global BatchPriceWriter(Id pbookId, List<PriceBookEntry> pList) {
        this.newRecords = 0;
        this.updatedRecords = 0;
        this.numErrors = 0;
        this.numExceptions = 0;
        this.errorMessages = new List<String>();
        this.pricebook = new PricebooksSelector().selectById(new Set<Id>{pbookId})[0];
        this.pbeList = pList;
    }

    global Iterable<List<sObject>>  start(Database.BatchableContext bc) {
        // Split the input list into batches of 200 objects each
        List<List<PricebookEntry>> batches = new List<List<PricebookEntry>>();
        Integer batchSize = 200;
        Integer numBatches = (Integer) Math.ceil(Decimal.valueOf(this.pbeList.size()) / batchSize);
        for (Integer i = 0; i < numBatches; i++) {
            Integer startIdx = i * batchSize;
            Integer endIdx = Math.min((i + 1) * batchSize, this.pbeList.size());
            List<PricebookEntry> aux = new List<PricebookEntry>();
            for (Integer j = startIdx; j< endIdx; j++) {
                aux.add(this.pbeList[j]);
            }
            batches.add(aux);
        }
        return (Iterable<List<sObject>>) batches;
    }

    global void execute(Database.BatchableContext BC, List<List<sObject>> scope) {
        try {
            this.logger = new SystemLog(this.logScenario);
            this.logger.addInfo('Updating pricebook ' + this.pricebook.Name);
            this.logger.addInfo('There are ' + this.pbeList.size() + ' records to update in PriceBookEntry');
            for (List<sObject> l :scope) {
                Database.UpsertResult[] upsertResults = Database.upsert(l, false);  // AllOrNothing is false
                this.parseUpsertResult(upsertResults);
            }
        } catch (Exception ex) {
            this.numExceptions++;
            this.logger.addError('Exception in BatchPriceWriter');
            this.logger.addError(ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        if ((this.numErrors + this.numExceptions) > 0) {
            this.pricebook.LastSyncResult__c = 'EXCEPTION';
        } else {
            this.pricebook.LastSyncResult__c = 'SUCCESS';
        }
        this.pricebook.LastSync__c = System.now();
        update this.pricebook;
        this.logSync();
    }

    private void parseUpsertResult(Database.UpsertResult[] results) {
        for (Database.UpsertResult result : results) {
            if (result.isSuccess()) {
                if (result.isCreated()) {
                    this.newRecords++;
                } else {
                    this.updatedRecords++;
                }
            } else {
                this.numErrors++;
                for (Database.Error error : result.getErrors()) {
                    this.errorMessages.add(error.message);
                }
            }
        }
    } // parseUpsertResult

    private void logSync() {
        Boolean success = ((this.numErrors + this.numExceptions) == 0);
        String newLine = '<br/>';
        String text = 'Price Book: ' + this.pricebook.Name + newLine;
        text += 'Success: ' + success + newLine;
        text += 'Processed: ' + this.pbeList.size() + newLine;
        text += 'Created: ' + this.newRecords + newLine;
        text += 'Updated: ' + this.updatedRecords + newLine;
        this.logger.addInfo(text);
        text = '';
        if (this.errorMessages.size() > 0) {
            text += newLine + 'Errors' + newLine + newLine;
            for (String message : this.errorMessages) {
                text += '- '  + message + newLine;
            }
            this.logger.addError(text);
        }    
        this.logger.saveLog();
    }
    
} // class