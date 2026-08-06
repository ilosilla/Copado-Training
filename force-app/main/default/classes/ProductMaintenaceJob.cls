global class ProductMaintenaceJob implements Database.Batchable<SObject>{

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('select Id, CurrencyIsoCode, UnitPrice, Pricebook2Id, Product2Id, ProductCode from PricebookEntry where CurrencyIsoCode = \'USD\' ');
    }

    global void execute(Database.BatchableContext BC, List<PricebookEntry> entries){
        String curr = 'USD';
        for (PricebookEntry entry : entries) {
            entry.isActive = true;
        }
        System.debug('>>> bloque');
        update entries;
    }
    /*
    global void execute(Database.BatchableContext BC, List<PricebookEntry> entries){
        String curr = 'USD';
        List<PricebookEntry> newEntries = new List<PricebookEntry>();
        for (PricebookEntry entry : entries) {
            PricebookEntry newEntry = new PricebookEntry();
            newEntry.CurrencyIsoCode = curr;
            newEntry.UnitPrice = entry.UnitPrice;
            newEntry.Pricebook2Id = entry.Pricebook2Id;
            newEntry.Product2Id = entry.Product2Id;
            newEntry.isActive = true;
            newEntries.add(newEntry);
        }
        System.debug('>>> Inserito blocco');
        insert newEntries;
    }
    */
    
    global void finish(Database.BatchableContext BC) {}

}