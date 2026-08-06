@IsTest(IsParallel=false) public with sharing class MasterClaimsPricebookSyncTest {

    @testSetup private static void testSetup() {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();
        Product2[] products = [select Id from Product2];
        for (Product2 product :products) {
            product.IsActive = true;
            product.SAPMaterialType__c = MasterClaimsPricebookSync.SPARES_MATERIAL_TYPE;
        }
        upsert products;
        
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'Claim Pricebook ';
        pb.isActive = true;
        pb.SapSync__c = true;
        pb.PriceType__c = 'UPR';
        pb.CurrencyIsoCode = 'USD'; 
        pb.IsForClaims__c = true;
        insert pb;
    }

    @isTest private static void test001() {
        Pricebook2 book = [select Id from Pricebook2 where IsForClaims__c = true limit 1];
        Assert.isNotNull(book.Id, 'There should be a claims pricebook');

        Test.startTest();
        MasterClaimsPricebookSync.executeInBatch();
        Test.stopTest();

        Product2[] products = [select Id from Product2];
        PricebookEntry[] entries = [select Id from PricebookEntry where Pricebook2Id = :book.Id];
        Assert.isTrue(entries.size() > 0, 'There should be at least one entry');
        Integer expected = products.size();
        Assert.areEqual(expected, entries.size(), 'All the products should be in the price book');
    }

    @isTest private static void testError1() {
        Pricebook2 book = [select Id, IsForClaims__c from Pricebook2 where IsForClaims__c = true limit 1];
        book.IsForClaims__c = false;
        update book;
        Boolean error = false;
        Test.startTest();
        try {
            MasterClaimsPricebookSync job = new MasterClaimsPricebookSync(book.Id);
        } catch (Exception ex) {
            error = true;
        }
        Test.stopTest();
        Assert.isTrue(error, 'Error expected (the book is not for claims)');
    }

    @isTest private static void testError2() {
        Pricebook2 book = [select Id, IsForClaims__c from Pricebook2 where IsForClaims__c = true limit 1];
        book.IsForClaims__c = false;
        delete book;
        Boolean error = false;
        Test.startTest();
        try {
            MasterClaimsPricebookSync job = new MasterClaimsPricebookSync(book.Id);
        } catch (Exception ex) {
            error = true;
        }
        Test.stopTest();
        Assert.isTrue(error, 'Error expected (the book does not exist)');
    }

}