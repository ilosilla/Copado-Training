/**
* @author 		Ramón Prades
* @date 		April 2022
* @group 		Products
* @description 	This class helps with some common tasks with the default price book.
*               COMMANDS:    
*               * CREATE: Populates the default price book with all products in a given currency
*               * ACTIVATE: Activates all entries in the selected price book entries
*/
global class PriceBookEntriesJob implements Database.Batchable<sObject>, Database.Stateful {
    
    String command = 'CREATE';
    String currencyCode = '';
    List<Id> currentEntries;
    Id defaultBookId;

    global PriceBookEntriesJob(String command, String ccode) {
        this.currencyCode = ccode;        
        Pricebook2 defaultBook = [select Id, Name, Description, isStandard from Pricebook2 where  IsStandard = true limit 1];
        System.debug('El defaultpricebook es ' + defaultBook.Name);        
        this.defaultBookId = defaultBook.Id;
        this.command = command;
        if (command == 'CREATE' ) {
            this.buildEntries();
            System.debug('currentEntries hay '+ this.currentEntries.size());
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryObj = '';
        if (this.command == 'CREATE') {
            queryObj = 'select Id, Material__c, Umv__c from Product2';
        } else {
            queryObj = 'select Id, isActive from PricebookEntry where Pricebook2Id = \'' + this.defaultBookId + '\' and CurrencyIsoCode = \'' + this.currencyCode +'\'';
        }
        return Database.getQueryLocator(queryObj);
    }//end method

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Me entran ' + scope.size() + ' para ' + this.currencyCode);
        if (this.command == 'CREATE') {
            this.commandCreate((List<Product2>) scope);
        } else {
            this.commandActivate((List<PricebookEntry>) scope);
        }
    }


    global void finish(Database.BatchableContext bc){
        List<PriceBookEntry> e = [select Id, Product2Id from PricebookEntry where Pricebook2Id = :this.defaultBookId and CurrencyIsoCode = :this.currencyCode];
        System.debug('Al terminar hay ' + e.size());
     }

     /*********************************************************/
     /******************** PRIVATE METHODS ********************/
     /*********************************************************/


     private void commandCreate(List<Product2> scope) {
        List<PriceBookEntry> entries = new List<PriceBookEntry>();
        for (Product2 product : scope) {
            if (!this.currentEntries.contains(product.Id)) {
                PriceBookEntry entry = new PriceBookEntry();            
                entry.Pricebook2Id = this.defaultBookId;
                entry.Product2Id = product.Id;
                entry.UPrice__c = product.Umv__c;
                entry.UnitPrice = 0;
                entry.CurrencyIsoCode = this.currencyCode;
                entry.isActive = true;
                entries.add(entry);
            }        
        }
        System.debug('COMMAND CREATE - Inserto un lote de ' + entries.size());
        insert(entries);
    }

    private void commandActivate(List<PricebookEntry> scope) {
        List<PriceBookEntry> entries = new List<PriceBookEntry>();
        for (PricebookEntry entry : scope) {
            entry.isActive = true;
            entries.add(entry);
        }
        update entries;
    }

    private void buildEntries() {
        this.currentEntries = new List<Id>();
        for (PriceBookEntry entry : [select Id, Product2Id from PricebookEntry where Pricebook2Id = :this.defaultBookId and CurrencyIsoCode = :this.currencyCode]) {
            this.currentEntries.add(entry.Product2Id);
        }
    }
}