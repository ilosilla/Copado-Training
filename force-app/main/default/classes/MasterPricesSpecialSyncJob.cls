/**
* @author 		Ramón Prades
* @date 		February 2023
* @group 		Prices
* @description 	Generates the pricebook entries from SAP ZB2B_PRICE2. It MUST be run after MasterPRicesSyncJob @deprecated
*/
global class MasterPricesSpecialSyncJob implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private final String logScenario = 'PRODUCTS&PRICES SYNC';
    private final String PRICES_PER_SALES_UNIT_KEY = 'UMV';

    private Pricebook2 pbook;
    private Integer maxItems = 0;
    private List<PricebookEntry> records;
    private List<String> errorMessages;
    private Boolean success = true;
    private Integer recordsProcessed = 0;
    private Integer recordsUpdated = 0;
    private Integer recordsCreated = 0;
    private SystemLog logger;
    private Boolean hasException = false;
    private Boolean fullUpdate = false;

    global MasterPricesSpecialSyncJob(Id pricebookId) {
        this.hasException = false;
        this.logger = new SystemLog(this.logScenario);
        this.pbook = new PricebooksSelector().selectById (new Set<Id>{pricebookId})[0];
        this.errorMessages = new List<String>();
        this.logger.addInfo('Syncing special prices for price book ' + this.pbook.Name);
    }
    
    global void setFullUpdate(Boolean value) {
        this.fullUpdate = value;        
    }

    global void setNumberOfItems(Integer num) {
        this.maxItems = num;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.buildQueryString());
    }

    global static void executeInBatch() {
        List<Pricebook2> priceBooks = new PricebooksSelector().selectBySapSync();
        for (Pricebook2 pBook : priceBooks) {
            if (pBook.SAPCustomer__c != null && !pBook.SamplesOnly__c) {
                Database.executeBatch(new MasterPricesSpecialSyncJob(pBook.Id));
            }
        }
    }

    global void execute(System.SchedulableContext context) {
        MasterPricesSyncJob.executeInBatch();
    } 

    global void execute(Database.BatchableContext bc, List<ZB2B_PRICE2__x> scope) {
        try {
            this.updatePrices(scope);
        } catch (Exception ex) {
            this.hasException = true;
            this.logger.addError(ex);
        }
    }

    global void finish(Database.BatchableContext bc){  
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

    private void updatePrices(List<ZB2B_PRICE2__x> sapPrices) {
        this.recordsProcessed += sapPrices.size();
        List<PricebookEntry> records = new List<PricebookEntry>();
        Map<String, Product2> sfProducts = this.readSalesforceProducts(sapPrices);
        Map<String, PricebookEntry> sfEntries = this.readSalesforcePrices(sfProducts.values());
        for (ZB2B_PRICE2__x sapPrice : sapPrices) {
            Product2 sfProduct = sfProducts.get(sapPrice.Material__c);
            if (sfProduct != null) {
                PricebookEntry entry = this.sapToSalesforce(sapPrice, this.pbook, sfProduct.Id);
                String key = entry.Product2Id + entry.CurrencyIsoCode;
                PricebookEntry oldEntry = sfEntries.get(key);
                if (oldEntry != null) {
                    entry.Id = oldEntry.Id;
                }
                records.add(entry);
            }
        }       
        /*
        Database.UpsertResult[] results = Database.upsert(records);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        } 
        */
    } // updatePrices

    private Map<String, Product2> readSalesforceProducts(LIst<ZB2B_PRICE2__x> sapPrices) {
        Set<String> pcodes = new Set<String>();
        for (ZB2B_PRICE2__x sapPrice : sapPrices) {
            if (!pcodes.contains(sapPrice.Material__c)) {
                pcodes.add(sapPrice.Material__c);
            }
        }
        List<Product2> products = [select Id, ProductCode from Product2 where ProductCode in :pcodes];
        Map<String, Product2> result = new Map<String, Product2>();
        for (Product2 product : products) {
            result.put(product.ProductCode, product);
        }
        return result;
    } // readSalesforceProducts

    private Map<String, PricebookEntry> readSalesforcePrices(List<Product2> sfProducts) {
        Map<String, PricebookEntry> result = new Map<String, PricebookEntry>();
        Set<Id> productIds = TypeConversionCommons.listToSet(sfProducts); 
        PricebookEntry[] entries = [select Id, Pricebook2Id, Product2Id, CurrencyIsoCode 
                                      from PricebookEntry 
                                      where Pricebook2Id = :this.pbook.Id 
                                      and Product2Id in :productIds
                                      for update];
        for (PricebookEntry entry :entries) {
            String key = entry.Product2Id + entry.CurrencyIsoCode;
            result.put(key, entry);
        }
        return result;
    }

    private  String buildQueryString() {        
        
        String objectName = 'ZB2B_PRICE2__x';
        
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String sep = ' ';
        for (String fieldValue : objectFields.keySet()) {
            query += sep + fieldValue;
            sep = ',';
        }
        query += ' FROM ' + objectName;
        
        String dateFilter = ' WHERE Cliente__c = \'' + this.pbook.SAPCustomer__c + '\'';
        if (!this.fullUpdate) {
            Integer daysFilter = getDaysBack();
            dateFilter += ' and Fmodifica__c >= ' + String.valueOf(Date.today().addDays(-daysFilter)) + 'T00:00:00.000+0000';
        }        
        query += dateFilter;

        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }

        return query;

    } // buildQueryString

    private Integer getDaysBack() {
        Integer days = 3;
        try {
            days = NB2B_AccountSelector.getNumDays(NB2B_GlobalConstants.CLASS_PRODUCTS);
        } catch (Exception ex) {
            days = 3;
        }
        return days;
    } // getDaysBack

    private PricebookEntry sapToSalesforce(ZB2B_PRICE2__x sapPrice, Pricebook2 pBook, Id productId){
        PricebookEntry entry = new PricebookEntry();
        entry.CurrencyIsoCode = sapPrice.Moneda__c;
        entry.Pricebook2Id = pBook.Id;
        entry.Product2Id = productId;
        entry.IsActive = true;

        // Prices per SAP Unit (SAP Prices)
        entry.SAPPrice__c = sapPrice.Prneto__c;
        entry.SAPPriceUnit__c = sapPrice.UPrecio__c;

        // Prices per sales unit (UMV)
        entry.UMVPrice__c = sapPrice.PrecioUMV__c;
        entry.UMVPriceUnit__c = sapPrice.UMV__c;

        // Según el tipo de libro, grabamos un precio u otro como precio de lista
        if (this.pbook.PriceType__c == this.PRICES_PER_SALES_UNIT_KEY) {
            entry.UnitPrice = entry.UMVPrice__c;
            entry.UPrice__c = entry.UMVPriceUnit__c;
        } else {
            entry.UnitPrice = entry.SAPPrice__c;
            entry.UPrice__c = entry.SAPPriceUnit__c;
        }

        entry.UseStandardPrice = false;
        
        return entry;
    }

    //private void parseUpsertResult(Database.UpsertResult result) {
        /*
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
        */
    //} // parseUpsertResult

    private void logSync() {
        String newLine = '<br/>';
        String text = 'Price Book: ' + this.pbook.Name + newLine;
        text += 'Success: ' + this.success + newLine;
        text += 'Processed: ' + this.recordsProcessed + newLine;
        text += 'Created: ' + this.recordsCreated + newLine;
        text += 'Updated: ' + this.recordsUpdated + newLine;
        this.logger.addInfo(text);
        text = '';
        if (this.errorMessages.size() > 0) {
            text += newLine + 'Errors' + newLine + newLine;
            for (String message : this.errorMessages) {
                text += '- '  + message + newLine;
            }
            this.logger.addError(text);
        }    
        Logger.saveLog();
    }

}