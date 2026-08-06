@isTest
public class PriceBookEntriesJobTest {
    @TestSetup
    static void makeData(){
        DataFactoryProduct.createProducts();
    }

    @IsTest
    static void test(){
        
        Test.startTest();
            Database.executeBatch(new PriceBookEntriesJob('CREATE', 'USD'));
            Database.executeBatch(new PriceBookEntriesJob('ACTIVATE', 'USD'));
        Test.stopTest();

        List<PricebookEntry> entries = [SELECT Id FROM PricebookEntry WHERE CurrencyIsoCode = 'USD'];
        System.assert(entries.size() > 0, 'Entries with USD not created');

        entries = [SELECT Id FROM PricebookEntry WHERE isActive = true];
        System.assert(entries.size() > 0, 'There are no entries active');
        
    }
}