/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Data Factories
* @description 	Creates products for testing
*/
public class DataFactoryProduct {

    public static final String DummyProductCode = '999999999';
    public static Boolean ignoreStandardPriceBook = false;
    public static Boolean skipPriceBooks = false;
    
    public static Pricebook2 createPricebook() {
        String random = TestUtils.generateRandomString(3);

        Pricebook2[] books = new List<Pricebook2>();
        
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'Test Pricebook ' + random;
        pb.isActive = true;
        pb.SapSync__c = true;
        pb.PriceType__c = 'UPR';
        if (Test.isRunningTest()) {
            books.add(pb);
        }
        
        //Instantiate the standard Pricebook2 record with StandardPricebookId        
        Pricebook2 spb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            SapSync__c = true,
            Bzirk__c = 'V10001',
            PriceType__c = 'UPR',
            ExecutionContext__c = 'FR'
        );
        
        if (!ignoreStandardPriceBook && Test.isRunningTest()) {
            books.add(spb);
        }        

        if (books.size() > 0) {
            upsert books;
        } 
        return pb;
    }

    public static Product2[] createProducts() {
        Pricebook2 pb = null;
        if (!skipPriceBooks) {
            pb = DataFactoryProduct.createPriceBook();
        }
        return DataFactoryProduct.createProducts(pb);
    }

    public static Product2[] createProducts(Pricebook2 pb) {
        Product2[] products = new List<Product2>();
        if (Test.isRunningTest()) {
             for (Integer i = 0; i<10; i++) {
                Product2 pr = new Product2(ProductCode = '10000000' + i, Name = 'PRODUCT ' + i, Umv__c = 'UN', IsActive = true, SAPMake__c = 'P');
                pr.StockKeepingUnit = pr.ProductCode;
                products.add(pr);                
            }
            Product2 dummy = new Product2(ProductCode = DataFactoryProduct.DummyProductCode, Name = 'DUMMY PRODUCT', Umv__c = 'UN', SAPMake__c = 'P');
            //dummy.StockKeepingUnit = dummy.ProductCode;
            products.add(dummy);
            insert products;
            if (pb != null) {
                Pricebook2 standardPB =  null;
                if (!ignoreStandardPriceBook) {
                    standardPB = [select Id from Pricebook2 where IsStandard = true limit 1];
                }
                PricebookEntry[] stdPrices = new List<PricebookEntry>();
                PricebookEntry[] prices = new List<PricebookEntry>();
                for(Product2 pr: products) {
                    PricebookEntry entry = new PricebookEntry();
                    entry.currencyIsoCode = 'USD';
                    entry.Pricebook2Id = pb.Id;
                    entry.Product2Id = pr.Id;
                    entry.UnitPrice = 1;
                    entry.isActive = true;
                    prices.add(entry);

                    if (!ignoreStandardPriceBook && standardPB != null) {
                        PricebookEntry stdEntry = new PricebookEntry();
                        stdEntry.currencyIsoCode = 'USD';
                        stdEntry.Pricebook2Id = standardPB.Id;
                        stdEntry.Product2Id = pr.Id;
                        stdEntry.UnitPrice = 1;
                        stdEntry.isActive = true;
                        stdPrices.add(stdEntry);
                    }

                }
                //insert stdPrices;
                insert prices;
            }
        }
        return products;
    }
}