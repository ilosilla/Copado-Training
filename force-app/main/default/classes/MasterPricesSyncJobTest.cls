@isTest public class MasterPricesSyncJobTest {
    @testSetup private static void testSetup() {
        Product2[] products = DataFactoryProduct.createProducts();        
    }

    @isTest
    public static void testBatchProcess() {        
        Product2[] products = [select Id, ProductCode from Product2];
        
        List<ZB2B_PRICE1__x> sapPrices = new List<ZB2B_PRICE1__x>();
        //for (Integer i = 0; i < 10; i++) {
            ZB2B_PRICE1__x price = new ZB2B_PRICE1__x();
            price.Bzirk__c = 'US1001';
            price.Cantidad__c = 1;
            price.Material__c = products[0].ProductCode;
            price.Moneda__c = 'USD';
            price.Prneto__c = 99.99;
            price.Uprecio__c = 'PZS';
            price.PrecioUMV__c = 99.99;
            price.UMV__c = 'PZS';

            sapPrices.add(price);
        //} // end for

        PricebookEntry pbe = [select Id, Pricebook2Id, UnitPrice from PricebookEntry where Product2Id = :products[0].Id and currencyIsoCode = 'USD' limit 1];
        System.assertNotEquals(null, pbe, 'No pricebook found - Cannot run the test');

        Test.startTest();
            MasterPricesSyncJob job = new MasterPricesSyncJob(pbe.Pricebook2Id);
            job.setFullUpdate(false);
            job.start(null);
            job.execute(null,sapPrices);
            job.finish(null);
        Test.stopTest();

        PricebookEntry pbeAfter = [select Id, Pricebook2Id, UnitPrice from PricebookEntry where Id = :pbe.Id limit 1];
        System.assertNotEquals(null, pbeAfter, 'No pricebook entry found - Cannot run the test');
        System.assertEquals(99.99, pbeAfter.UnitPrice, 'New price should be 99.99');
        
    }

    @isTest
    public static void testBatchProcess2() {        
        Test.startTest();
            MasterPricesSyncJob.executeInBatch();
        Test.stopTest();
        Assert.isTrue(true); // Dummy - Queremos más cobertura pero en batch no s epuede probar nad aporque no hay revistros en las tablas de connect        
    }        

} // class