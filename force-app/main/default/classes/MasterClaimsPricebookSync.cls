/**
 * @author         Ramón Prades
 * @date           December 2024
 * @layer          Products & Prices
 * @description    Creates and updates the claims pricebooks. These pricebooks are made with the union
*/
@SuppressWarnings('PMD.EmptyStatementBlock')
global with sharing class MasterClaimsPricebookSync implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private Pricebook2 pricebook;
    public static final String SPARES_MATERIAL_TYPE = 'ZRYC';
    private final String logScenario = 'PRICES-SYNC';
    private SystemLog logger;
    private Integer nInserts = 0;
    private Integer nUpdates = 0;
    private Integer nErrors = 0;
    
    global MasterClaimsPricebookSync(Id bookId) {
        this.logger = new SystemLog(this.logScenario);
        this.logger.setTag('CLAIMS');
        this.nInserts = 0;
        this.nUpdates = 0;
        try {
            this.pricebook = new PricebooksSelector().selectById(new Set<Id>{bookId})[0];
            this.logger.addInfo('Sincronizando libro de CLAIMS: ' + this.pricebook.Name);
            this.logger.addInfo('La divisa del libro es: ' + this.pricebook.CurrencyIsoCode);
        } catch(Exception ex) {
            this.logger.addError(ex);
            this.logger.setSummary('No se ha actualizado el libro de CLAIMS');
            this.logger.saveLog(true);
        }
        if (!this.pricebook.IsForClaims__c) {
            throw new ContextException('The referenced book mis not a claims book');
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.buildQuery());
    }

    global void execute(System.SchedulableContext context) {
        Database.executeBatch(this);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Check if the products already exist on the book
        List<PricebookEntry> entries = new List<PricebookEntry>();
        Map<Id, PricebookEntry> existingEntries = this.getExistingEntries(this.pricebook.Id, (List<Product2>) scope);
        for (Product2 product :(List<Product2>) scope) {
            String key = product.Id;
            PricebookEntry entry = existingEntries.get(key);
            if (entry != null) {
                if (entry.isActive != product.isActive) {
                    entry.isActive = product.isActive;
                    entries.add(entry);
                }
            } else {
                if (product.IsActive) {
                    entry = this.createPriceEntry(this.pricebook.Id, product, this.pricebook.CurrencyIsoCode);
                    entries.add(entry);
                }
            }
            if (entries.size() > 190) { // Dejamos un margen por seguridad ya que insertamos registros para cada moneda y nos podemos pasar de 200
                Database.UpsertResult[] results = Database.upsert(entries, false);
                this.parseUpsertResult(results, entries);
                entries.clear();
            }
        }
        if (entries.size() > 0) {
            Database.UpsertResult[] results = Database.upsert(entries, false);
            this.parseUpsertResult(results, entries);
        }
    }

    global void finish(Database.BatchableContext bc) {
        try {
            this.logger.addInfo('Se han insertado nuevos productos: ' + this.nInserts);
            this.logger.addInfo('Se han actualizado entradas: ' + this.nUpdates);
            this.logger.setSummary('El libro de CLAIMS se ha actualizado con éxito');
            this.pricebook.LastSyncResult__c = 'SUCCESS';
            this.pricebook.LastSync__c = System.now();
            update this.pricebook;        
            this.logger.saveLog(true);
        } catch (Exception ex) {
            this.logger.setSummary('Error al actualizar el libro de CLAIMS');
            this.logger.addError(ex);
            this.logger.saveLog(true);
        }
    }  
    
    global static void executeInBatch() {
        List<Pricebook2> priceBooks = [select Id, Name, IsForClaims__c, SAPSync__c, IsActive from Pricebook2 where IsForClaims__c = true and IsActive = true];
        for (Pricebook2 pBook : priceBooks) {
            Database.executeBatch(new MasterClaimsPricebookSync(pBook.Id));
        }
    }

    /* ============================================ */

    private String buildQuery() {
        return 'select Id, StockKeepingUnit, SAPItemGroup__r.SAPGroup__c, SAPMaterialType__c, SalesUnit__c, IsActive from Product2 ';
            //+ 'where SAPItemGroup__r.SAPGroup__c like \'PT%\' or SAPMaterialType__c = \'' 
            //+ SPARES_MATERIAL_TYPE + '\'';
    }

    private PricebookEntry createPriceEntry(Id pricebookId, Product2 product, String currencyCode){
        PricebookEntry entry = new PricebookEntry();
        entry.CurrencyIsoCode = currencyCode;
        entry.Pricebook2Id = pricebookId;
        entry.Product2Id = product.Id;
        entry.IsActive = true;
        entry.UPrice__c = product.SalesUnit__c;
        entry.UnitPrice = 0;
        entry.UseStandardPrice = false;
        return entry;
    }

    private Map<Id, PricebookEntry> getExistingEntries(Id bookId, List<Product2> scope) {
        Map<Id, PricebookEntry> entriesMap = new Map<Id, PricebookEntry>();
        List<Id> productIds = TypeConversionCommons.extractListOfIds(scope);
        PricebookEntry[] entries = [select Id, Product2Id, Pricebook2Id, UPrice__c, IsActive, CurrencyIsoCode from Pricebookentry where Pricebook2Id = :bookId and Product2Id in :productIds];
        for (PricebookEntry entry :entries) {
            entriesMap.put(entry.Product2Id, entry);
        }
        return entriesMap;
    }

    private Boolean parseUpsertResult(Database.UpsertResult[] results, List<PricebookEntry> entries) {
        Boolean isSuccess = true;
        this.logger.addDebug('Parsing upsertResults');
        Integer i = 0;
        for (Database.UpsertResult result : results) {
            if (result.isSuccess()) {
                if (result.isCreated()) {
                    this.nInserts++;
                } else {
                    this.nUpdates++;
                }
            } else {
                isSuccess = false;
                this.nErrors++;
                this.logger.addError('Error actualizando claims entry para book ' + entries[i]?.Pricebook2Id + ' y producto ' + entries[i]?.Product2Id);
                for (Database.Error error : result.getErrors()) {
                    this.logger.addError('- ' + error.message);
                }
            }
            i++;
        }
        return isSuccess;
    } // parseUpsertResult

}