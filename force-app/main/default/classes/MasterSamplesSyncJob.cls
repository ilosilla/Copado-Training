/**
* @author 		Ramón Prades
* @date 		September 2022
* @group 		Prices
* @description 	Generates the pricebook entries from samples only. 
*
*               Selects all PriceBooks that are:
*               - Active
*               - Samples onlly
*               - SAP Synced
*
*               Writes output in SysteLog
*/
global class MasterSamplesSyncJob implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private final String logScenario = 'PRICES-SYNC';

    private Pricebook2 pbook;
    private Integer maxItems = 0;
    private List<PricebookEntry> records;
    private List<String> errorMessages;
    private Boolean success = true;
    private Integer recordsProcessed = 0;
    private Integer recordsUpdated = 0;
    private Integer recordsCreated = 0;
    private Integer recordsInactive = 0;
    private SystemLog logger;
    private Boolean hasException = false;
    private Set<String> activeSamples;

    global MasterSamplesSyncJob(Id pricebookId) {
        this.logger = new SystemLog(this.logScenario);
        this.logger.setTag('SAMPLES');
        this.hasException = false;
        this.pbook = new PricebooksSelector().selectById (new Set<Id>{pricebookId})[0];
        this.errorMessages = new List<String>();
        this.activeSamples = new Set<String>();
    }

    global void setNumberOfItems(Integer num) {
        this.maxItems = num;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //this.deleteEntries(this.pbook.Id);
        return Database.getQueryLocator(this.buildQueryString(this.pbook.Bzirk__c));
    }

    global static void executeInBatch() {
        List<Pricebook2> priceBooks = [select Id, Name, SamplesOnly__c, SAPSync__c, Bzirk__c, IsActive from Pricebook2 where SamplesOnly__c = true and SAPSync__c = true and IsActive = true];
        for (Pricebook2 pBook : priceBooks) {
            if (String.isNotBlank(pBook.Bzirk__c)) {
                Database.executeBatch(new MasterSamplesSyncJob(pBook.Id));
            }
        }
    }

    global void execute(System.SchedulableContext context) {
        MasterSamplesSyncJob.executeInBatch();
    } 

    global void execute(Database.BatchableContext bc, List<ZSFMatOrgv__x> scope) {
        if (this.pbook.SamplesOnly__c) {
            try {
                 this.logger.addInfo('Syncing pricebook ' + this.pbook.Name);
                this.updateSamples(scope);
            } catch (Exception ex) {
                this.hasException = true;
                this.logger.addError(ex);
            }        
        }
    }

    global void finish(Database.BatchableContext bc){          
        this.setInactiveRecords();
        if (this.hasException) {
            this.pbook.LastSyncResult__c = 'EXCEPTION';
        } else {
            this.pbook.LastSyncResult__c = 'SUCCESS';
        }
        this.pbook.LastSync__c = System.now();
        update this.pbook;
        this.logSync();
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private void updateSamples(List<ZSFMatOrgv__x> sapProducts) {
        Product2[] products = readProducts(sapProducts);
        Map<String, PricebookEntry> entries = this.readPriceEntries(products);
        this.recordsProcessed += products.size();
        List<PricebookEntry> records = new List<PricebookEntry>();
        for (Product2 product : products) {
            if (product.IsActive) {
                this.activeSamples.add(product.ProductCode);
                PricebookEntry entry = (PricebookEntry) entries.get(product.Id);
                if (entry == null) {
                    entry = this.createPriceEntry(product, this.pbook);
                }
                entry.IsActive = true;
                records.add(entry);            
            }
        }       
        Database.UpsertResult[] results = Database.upsert(records);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        } 
    } 

    private void setInactiveRecords() {
        try {
            this.logger.addInfo('Entering setInactive with active records = ' + this.activeSamples.size());
            Integer batchSize = 200;
            List<PricebookEntry> inactive = new List<PricebookEntry>();
            for (PricebookEntry entry : [select Id, CurrencyIsoCode, ProductCode, IsActive from PricebookEntry where Pricebook2Id = :this.pbook.Id and IsActive = true]) {
                if (entry.CurrencyIsoCode != this.pbook.CurrencyIsoCode || !this.activeSamples.contains(entry.ProductCode)) {
                    entry.IsActive = false;
                    inactive.add(entry);
                    if (inactive.size() == batchSize) {
                        this.recordsInactive += batchSize;
                        update inactive;
                        inactive.clear();
                    }
                }
            }
            if (inactive.size() > 0) {
                this.recordsInactive += inactive.size();
                update inactive;
            }
        } catch (Exception ex) {
            this.hasException = true;
            this.logger.addError(ex);
        }
    }

    private List<Product2> readProducts(ZSFMatOrgv__x[] sapProducts) {
        Set<String> productCodes = new Set<String>();
        for (ZSFMatOrgv__x product : sapProducts) {
            if (!productCodes.contains(product.Material__c)) {
                productCodes.add(product.Material__c);
            }
        }
        return [select Id, ProductCode, Name, SalesUnit__c, IsActive from Product2 where ProductCode in :productCodes];
    }

    private Map<String, PricebookEntry> readPriceEntries(List<Product2> products) {
        Map<String, PricebookEntry> result = new Map<String, PricebookEntry>();
        Set<Id> productIds = TypeConversionCommons.listToSet(products); 
        PricebookEntry[] entries = [select Id, Pricebook2Id, Product2Id, CurrencyIsoCode from PricebookEntry where Pricebook2Id = :this.pbook.Id and Product2Id in :productIds and CurrencyIsoCode = :this.pbook.CurrencyIsoCode];
        for (PricebookEntry entry :entries) {
            String key = entry.Product2Id;
            result.put(key, entry);
        }
        return result;
    }

    public  String buildQueryString(String salesOrg) {        
        
        String objectName = 'ZSFMatOrgv__x';
        
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String sep = ' ';
        for (String fieldValue : objectFields.keySet()) {
            IF (fieldValue.toLowerCase() != 'taxpolicyid') {
                query += sep + fieldValue;
                sep = ',';
            }
        }
        query += ' FROM ' + objectName;

        String dateFilter = ' WHERE Vkorg__c = \'' + salesOrg + '\' and IsSample__c = true';
        query += dateFilter;

        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }

        return query;

    } // buildQueryString

    private PricebookEntry createPriceEntry(Product2 product2, Pricebook2 pBook){
        PricebookEntry entry = new PricebookEntry();
        entry.CurrencyIsoCode = pbook.CurrencyIsoCode;
        entry.Pricebook2Id = pBook.Id;
        entry.Product2Id = product2.Id;
        entry.IsActive = true;
        // entry.UnitofPrice__c = sapPrice.Uprecio__c;
        entry.UPrice__c = product2.SalesUnit__c;
        entry.UnitPrice = 0;
        entry.UseStandardPrice = false;
        return entry;
    }

    private void parseUpsertResult(Database.UpsertResult result) {
        this.success = (this.success && result.isSuccess());
        if (result.isSuccess()) {
            if (result.isCreated()) {
                this.recordsCreated++;
            } else {
                this.recordsUpdated++;
            }
        } else {
            this.success = false;
            for (Database.Error error : result.getErrors()) {
                this.errorMessages.add(error.message);
            }
        }
    } // parseUpsertResult

    private void logSync() {
        String newLine = '<br/>';
        String text = '- Price Book: ' + this.pbook.Name + newLine;
        text += '- Success: ' + this.success + newLine;
        text += '- Processed: ' + this.recordsProcessed + newLine;
        text += '- Created: ' + this.recordsCreated + newLine;
        text += '- Updated: ' + this.recordsUpdated + newLine;
        text += '- Inactive: ' + this.recordsInactive + newLine + newLine;
        this.logger.addInfo(text);

        text = '';
        if (this.errorMessages.size() == 0) {
            this.logger.setSummary('Libro de muestras actualizado: ' + this.pbook.Name);
        } else {
            this.logger.setSummary('Error actualizando libro de muestras ' + this.pbook.Name);
            text += newLine + 'Errors' + newLine + newLine;
            for (String message : this.errorMessages) {
                text += '- '  + message + newLine;
            }
            this.logger.addError(text);
        }    
        this.logger.saveLog();
    }

}