/**
* @author 		Ramón Prades
* @date 		September 2022
* @group 		Prices
* @description 	Generates the pricebook entries from SAP.  
*/
global class BatchPriceUpdater implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private final String logScenario = 'PRICES-SYNC';
    private final String PRICES_PER_SALES_UNIT_KEY = 'UMV';

    private class BatchPriceUpdaterException extends Exception {}

    private Pricebook2 pbook;
    private Integer numberOfDays = 3;
    private Integer maxItems = 0;
    private Boolean useSpecialPrices = false;

    //private List<PricebookEntry> recordsToUpdate;
    // private List<String> errorMessages;
    // private Boolean success = true;
    private SystemLog logger;
    private Boolean hasException = false;
    private Boolean fullUpdate = false;
    private Set<String> epProductCodes;
    private Integer numRecords = 0;
    private Integer newRecords = 0;
    private Integer updatedRecords = 0;
    private Integer numErrors = 0;

    global BatchPriceUpdater(Id pricebookId) {
        this.numRecords = 0;
        this.hasException = false;
        this.newRecords = 0;
        this.updatedRecords = 0;
        this.numErrors = 0;
        this.logger = new SystemLog(this.logScenario);
        this.logger.setTag('PRICEBOOK');
        this.pbook = new PricebooksSelector().selectById (new Set<Id>{pricebookId})[0];
        this.useSpecialPrices = (this.pbook.SAPCustomer__c != null && this.pbook.SAPCustomer__c > 0);
        this.logger.addInfo('Reading changes in price book ' + this.pbook.Name);
        this.logger.addInfo('*****************************');
        this.epProductCodes = this.pbook.EntitlementPolicy__c != null ? this.loadEPProductCodes(this.pbook.EntitlementPolicy__c) : null;
        //this.recordsToUpdate = new List<PricebookEntry>();
    }

    global void setNumberOfDays(Integer days) {
        this.numberOfDays = Math.abs(days);
    }

    global void setFullUpdate(Boolean value) {
        this.fullUpdate = value;        
    }

    global void setNumberOfItems(Integer num) {
        this.maxItems = num;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        if (this.useSpecialPrices) {
            query = this.buildSpecialQueryString(); 
        } else {
            query = this.buildQueryString();
        }
        return Database.getQueryLocator(query);
    } // start

    global static void executeInBatch() {
        List<Pricebook2> priceBooks = new PricebooksSelector().selectBySapSync();
        for (Pricebook2 pBook : priceBooks) {
            if (!pBook.SamplesOnly__c) {
                Database.executeBatch(new BatchPriceUpdater(pBook.Id));                
            }
        }  
        // Actualizar claims
        MasterClaimsPricebookSync.executeInBatch();     
    } // executeInBatch

    global void execute(System.SchedulableContext context) {
        BatchPriceUpdater.executeInBatch();
    } 

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            this.numRecords += scope.size();
            List<PricebookEntry> entries = this.readPrices(scope);
            Database.UpsertResult[] upsertResults = Database.upsert(entries, false);
            Boolean success = this.parseUpsertResult(upsertResults);
            this.logger.addDebug('Batch upserted with success = ' + success);
        } catch (Exception ex) {
            this.hasException = true;
            this.logger.addDebug('EXCEPTION RECEIVED:');
            this.logger.addError(ex);
        }
    }

    global void finish(Database.BatchableContext bc){    
        if ((this.numErrors > 0) || this.hasException) {
            this.pbook.LastSyncResult__c = 'EXCEPTION';            
        } else {
            this.pbook.LastSyncResult__c = 'SUCCESS';
        }
        this.pbook.LastSync__c = System.now();
        update this.pbook;
        if (this.epProductCodes != null) {
            this.deactivateOutOfScopeEntries();
        }
        this.logSummary();
        /*
        if (this.recordsToUpdate.size() > 0) {
            BatchPriceWriter writer = new BatchPriceWriter(this.pbook.Id, this.recordsToUpdate);
            Database.executeBatch(writer);
        }
        */
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private Set<String> loadEPProductCodes(Id policyId) {
        Set<String> codes = new Set<String>();
        for (CommerceEntitlementProduct ep : [SELECT Product.StockKeepingUnit FROM CommerceEntitlementProduct WHERE PolicyId = :policyId]) {
            if (ep.Product != null) {
                codes.add(ep.Product.StockKeepingUnit);
            }
        }
        this.logger.addInfo('EP filter active: ' + codes.size() + ' products in scope');
        return codes;
    }

    private void deactivateOutOfScopeEntries() {
        try {
            List<PricebookEntry> toDeactivate = new List<PricebookEntry>();
            for (PricebookEntry entry : [SELECT Id, Product2.StockKeepingUnit, IsActive FROM PricebookEntry WHERE Pricebook2Id = :this.pbook.Id AND IsActive = true]) {
                if (!this.epProductCodes.contains(entry.Product2.StockKeepingUnit)) {
                    entry.IsActive = false;
                    toDeactivate.add(entry);
                }
            }
            if (!toDeactivate.isEmpty()) {
                update toDeactivate;
                this.logger.addInfo('Deactivated ' + toDeactivate.size() + ' out-of-scope entries');
            }
        } catch (Exception ex) {
            this.hasException = true;
            this.logger.addError(ex);
        }
    }

    private List<PricebookEntry> readPrices(List<SObject> sapPrices) {
        List<PricebookEntry> recordsToUpdate = new List<PricebookEntry>();
        Map<String, Product2> productsMap = this.readProductsMap(sapPrices);
        Map<String, PricebookEntry> pricesMap = this.readPricebookEntriesMap(productsMap.values());
        this.logger.addDebug('Reading a batch of ' + sapPrices.size() + ' sapPrices[]');
        for (SObject sapPrice : sapPrices) {
            String material = (String) sapPrice.get('Material__c');
            String currencyCode = (String) sapPrice.get('Moneda__c');
            Product2 product = productsMap.get(material);
            if (product != null) {
                String key = this.buildPricebookEntryKey(product.Id, currencyCode);
                PricebookEntry entry = pricesMap.get(key);
                if (entry == null) {
                    entry =  new PricebookEntry();
                    entry.Pricebook2Id = this.pbook.Id;
                    entry.Product2Id = product.Id;
                    entry.CurrencyIsoCode = currencyCode;
                }
                this.setPrices(entry, sapPrice);
                recordsToUpdate.add(entry);
            }
        }    
        return recordsToUpdate;   
    } // readPrices

    private void setPrices(PricebookEntry entry, SObject sapPrice) {
        entry.IsActive = true;
        
        // Prices per SAP Unit (SAP Prices)
        entry.SAPPrice__c = (Decimal) sapPrice.get('Prneto__c');
        entry.SAPPriceUnit__c = (String) sapPrice.get('UPrecio__c');

        // Prices per sales unit (UMV)
        entry.UMVPrice__c = (Decimal) sapPrice.get('PrecioUMV__c');
        entry.UMVPriceUnit__c = (String) sapPrice.get('UMV__c');

        // Según el tipo de libro, grabamos un precio u otro como precio de lista
        if (this.pbook.PriceType__c == this.PRICES_PER_SALES_UNIT_KEY) {
            entry.UnitPrice = entry.UMVPrice__c;
            entry.UPrice__c = entry.UMVPriceUnit__c;
        } else {
            entry.UnitPrice = entry.SAPPrice__c;
            entry.UPrice__c = entry.SAPPriceUnit__c;
        }

        // entry.UnitofPrice__c = sapPrice.Uprecio__c;
        entry.UseStandardPrice = false;
        
    } // setPrices

    private Map<String, Product2> readProductsMap(LIst<SObject> sapRecords) {
        Set<String> productCodes = new Set<String>();
        for (SObject record : sapRecords) {
            String material = (String) record.get('Material__c');
            productCodes.add(material);
        }
        List<Product2> products = [select Id, ProductCode from Product2 where ProductCode in :productCodes];
        Map<String, Product2> productsMap = new Map<String, Product2>();
        for (Product2 product : products) {
            productsMap.put(product.ProductCode, product);
        }
        return productsMap;
    } // readProducts

    private Map<String, PricebookEntry> readPricebookEntriesMap(List<Product2> products) {
        Map<String, PricebookEntry> result = new Map<String, PricebookEntry>();
        Set<Id> productIds = TypeConversionCommons.listToSet(products); 
        PricebookEntry[] entries = [select Id, Pricebook2Id, Product2Id, CurrencyIsoCode 
                                      from PricebookEntry 
                                      where Pricebook2Id = :this.pbook.Id 
                                      and Product2Id in :productIds];
        for (PricebookEntry entry :entries) {
            String key = this.buildPricebookEntryKey(entry.Product2Id, entry.CurrencyIsoCode);
            result.put(key, entry);
        }
        return result;
    } // readPricebookEntriesMap

    private String buildPricebookEntryKey(Id productId, String currencyCode) {
        return String.valueOf(productId) + '|' + currencyCode;
    } // buildPricebookEntryKey

    private Set<String> getSapPriceListCodes() {
        Set<String> sapPriceListCodes = new Set<String>();
        if (String.isBlank(this.pbook.Bzirk__c)) {
            return sapPriceListCodes;
        }

        for (String sapPriceListCode : this.pbook.Bzirk__c.split(';')) {
            sapPriceListCode = sapPriceListCode.trim();
            if (String.isNotBlank(sapPriceListCode)) {
                sapPriceListCodes.add(sapPriceListCode);
            }
        }
        return sapPriceListCodes;
    } // getSapPriceListCodes

    private String buildQuotedInClause(Set<String> values) {
        List<String> quotedValues = new List<String>();
        for (String value : values) {
            quotedValues.add('\'' + String.escapeSingleQuotes(value) + '\'');
        }
        return '(' + String.join(quotedValues, ',') + ')';
    } // buildQuotedInClause

    private  String buildQueryString() {     
        String objectName = 'ZB2B_PRICE1__x';        
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ' FROM ' + objectName;
        Set<String> sapPriceListCodes = this.getSapPriceListCodes();
        if (sapPriceListCodes.isEmpty()) {
            throw new BatchPriceUpdaterException('No SAP price list codes are configured in Pricebook2.Bzirk__c for pricebook ' + this.pbook.Name + ' (' + this.pbook.Id + ').');
        }
        query += ' WHERE bzirk__c IN ' + this.buildQuotedInClause(sapPriceListCodes);
        if (this.epProductCodes != null && !this.epProductCodes.isEmpty()) {
            query += ' AND Material__c IN ' + this.buildQuotedInClause(this.epProductCodes);
        }
        if (!this.fullUpdate) {        
            query += ' and Fmodifica__c >= ' + String.valueOf(Date.today().addDays(-this.numberOfDays)) + 'T00:00:00.000+0000';
        }        
        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }
        return query;
    } // buildQueryString

    private String buildSpecialQueryString() {                
        String objectName = 'ZB2B_PRICE2__x';        
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ' FROM ' + objectName;
        query += ' WHERE Cliente__c = \'' + this.pbook.SAPCustomer__c + '\'';
        if (this.epProductCodes != null && !this.epProductCodes.isEmpty()) {
            query += ' AND Material__c IN ' + this.buildQuotedInClause(this.epProductCodes);
        }
        if (!this.fullUpdate) {        
            query += ' and Fmodifica__c >= ' + String.valueOf(Date.today().addDays(-this.numberOfDays)) + 'T00:00:00.000+0000';
        }        
        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }
        return query;
    } // buildSpecialQueryString


    private Boolean parseUpsertResult(Database.UpsertResult[] results) {
        Boolean isSuccess = true;
        this.logger.addDebug('Parsing upsertResults');
        for (Database.UpsertResult result : results) {
            if (result.isSuccess()) {
                if (result.isCreated()) {
                    this.newRecords++;
                } else {
                    this.updatedRecords++;
                }
            } else {
                isSuccess = false;
                this.numErrors++;
                for (Database.Error error : result.getErrors()) {
                    this.logger.addError(error.message);
                }
            }
        }
        return isSuccess;
    } // parseUpsertResult

    private void logSummary() {
        Boolean success = ((this.numErrors == 0) && !this.hasException);
        String newLine = '<br/>';
        String text = 'Price Book: ' + this.pbook.Name + ' synced!' + newLine;
        text += 'Success: ' + success + newLine;
        text += 'Processed: ' + this.numRecords + newLine;
        text += 'Created: ' + this.newRecords + newLine;
        text += 'Updated: ' + this.updatedRecords + newLine;
        text += 'Errors: ' + this.numErrors + newLine;
        if (this.numErrors > 0) {            
            this.logger.setSummary('Error sincronizando el libro ' + this.pbook.Name);
        } else {
            this.logger.setSummary('Libro actualizado con éxito: ' + this.pbook.Name);
        }
        this.logger.addInfo(text);
        this.logger.saveLog();
    }

}