@isTest public class BatchPriceWriterTest {
    
    private static final String K_TEST_BZIRK = 'TST%';
    private static final Integer K_NUM_RECORDS = 506;

    @testSetup private static void testSetup() {
        Pricebook2 pbook = DataFactoryProduct.createPricebook();
        pbook.Bzirk__c = K_TEST_BZIRK;
        update pbook;
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < K_NUM_RECORDS; i++) {
            Integer pc = 1000000 + i;
            Product2 pr = new Product2(ProductCode = String.valueOf(pc), Name = 'PRODUCT ' + i);
            products.add(pr);                
        }
        insert products;
    }

    @isTest private static void testBatch() {
        Pricebook2 pbook = [select Id from Pricebook2 where bzirk__c = :K_TEST_BZIRK limit 1];
        List<PriceBookEntry> entries = buildPBE(pbook.Id);
        Test.startTest();
        BatchPriceWriter writer = new BatchPriceWriter(pbook.Id, entries);
        Database.executeBatch(writer);
        Test.stopTest();
        List<PriceBookEntry> newEntries = [select Id, UnitPrice from PricebookEntry where Pricebook2Id = :pbook.Id];
        System.assertEquals(entries.size() - 1, newEntries.size(), 'Error upserting'); // -1 because there's a record with errors that won't be inserted
    }

    private static List<PriceBookEntry> buildPBE(Id pbook) {
        List<PriceBookEntry> entries = new List<PricebookEntry>();
        List<Product2> products = [select Id, ProductCode from Product2];
        for (Product2 product :products) {
            PricebookEntry entry = new PricebookEntry();
            entry.currencyIsoCode = 'USD';
            entry.Pricebook2Id = pbook;
            entry.Product2Id = product.Id;
            entry.UnitPrice = 10;
            entry.isActive = true;
            entries.add(entry);
        }

        // Añadimos uno para que de error y probar la parte de errores
        PricebookEntry entry = new PricebookEntry();
        entry.currencyIsoCode = 'USD';
        entry.Pricebook2Id = pbook;
        entry.Product2Id = null;
        entry.UnitPrice = 10;
        entry.isActive = true;
        entries.add(entry);

        return entries;
    }
}