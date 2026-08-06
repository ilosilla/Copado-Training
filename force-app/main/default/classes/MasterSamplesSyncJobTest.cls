/**
 * Test class
 */

 @IsTest(IsParallel=false) public class MasterSamplesSyncJobTest {

    @testSetup private static void testSetup() {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        Product2[] products = DataFactoryProduct.createProducts();
        Pricebook2 book = [select Id, SamplesOnly__c from Pricebook2 limit 1];
        List<Pricebook2> books = new PricebooksSelector().selectById(new Set<Id>{book.Id});

        books[0].Id = null;
        books[0].SamplesOnly__c = true;
        books[0].Bzirk__c = '502';
        insert books[0];

        for (Product2 p : products) {
            p.IsSample__c = true;
            p.IsActive = true;
        }   
        update products;  
    }


    @isTest
    public static void testBatchProcess() {        
        MasterSamplesSyncJob job;
        List<ZSFMatOrgv__x> sapProducts = new List<ZSFMatOrgv__x>();
        Product2[] products = [select ProductCode from Product2];
        for (Product2 p: products) {
            sapProducts.add(new ZSFMatOrgv__x(Material__c = p.ProductCode, Vkorg__c = '502', IsSample__c = true ));
        }
        Pricebook2 book = [select Id, SamplesOnly__c from Pricebook2 where SamplesOnly__c = true and Bzirk__c = '502' limit 1];
        Assert.areEqual(true, book.SamplesOnly__c, 'Only samplkes pricebooks allowed');
        Test.startTest();
            //MasterSamplesSyncJob.executeInBatch();
            job = new MasterSamplesSyncJob(book.Id);
            job.setNumberOfItems(100);
            job.start(null);
            job.execute(null, sapProducts);
            job.finish(null);            
        Test.stopTest();
        PricebookEntry[] entries = [select Id from PricebookEntry where Pricebook2Id = :book.Id];
        System.assertNotEquals(0, entries.size(), 'No entries created');
        
    }

    @isTest public static void  test2() {        
        MasterSamplesSyncJob.executeInBatch();

    } 


} // class