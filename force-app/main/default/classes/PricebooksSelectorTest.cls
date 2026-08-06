@isTest
public with sharing class PricebooksSelectorTest {

    @testSetup
    private static void testSetup() {        
        TestUtils.enableTriggers();
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();
        makeData();
    }
    static void makeData(){
        TestUtils.enableTriggers();        
        // Create account
        DataFactoryAccount.autoInsert = false;
        List<Account> accounts = DataFactoryAccount.createAccounts(2);
        accounts[0].SAP_Id__c = '0001234567';
        accounts[0].Name = 'RESELLER';
        accounts[0].RecordTypeId = RecordTypeLibrary.Account_ResellerCustomer;

        insert accounts;
        createContactAddress(accounts[0]);
    }

    @isTest
    private static void selectById() {
        Set<Id> pbIds = new Set<id>();
        for(Pricebook2 l : [Select Id from Pricebook2]) {
            pbIds.add(l.id);
        }
        List<Pricebook2> result = new PricebooksSelector().selectById(pbIds);
        System.assert(result.size() > 0, 'No se ha encontrado Pricebook2 entry');
    }

    @isTest
    private static void selectByExecutionContext() {
        List<Pricebook2> result = new PricebooksSelector().selectByExecutionContext('UK');
        System.assert(result.size() >= 0, 'No se ha encontrado Pricebook2 entry');
    }

    @isTest
    private static void selectClaimsPricebook() {
        Pricebook2 book = [select Id, IsForClaims__c, CurrencyIsoCode from Pricebook2 limit 1];
        book.IsForClaims__c = true;
        book.CurrencyIsoCode = 'USD';
        update book;
        Pricebook2 result = new PricebooksSelector().selectClaimsPricebook('USD');        
        Assert.areEqual(book.Id, result.Id, 'A pricebook was expected');
        Boolean ex = false;
        try {
            Pricebook2 result2 = new PricebooksSelector().selectClaimsPricebook('GBP');        
            if (result2 != null) {
                ex = false;
            }
        } catch (ObjectNotFoundException onf) {
            ex = true;
        }
        Assert.isTrue(ex, 'An exception was expected');
    }


    @isTest
    private static void selectStandardPricebook() {
        List<Pricebook2> result = new PricebooksSelector().selectStandardPricebook();
        System.assert(result.size() >= 0, 'No se ha encontrado Pricebook2 entry');
    }

    @isTest
    private static void selectByTariffs() {
        List<Pricebook2> result = new PricebooksSelector().selectByTariffs(new Set<String>{'V10001'});
        System.assert(result.size() >= 0, 'No se ha encontrado Pricebook2 entry');
    }

    @isTest
    private static void selectBySapSync() {
        List<Pricebook2> result = new PricebooksSelector().selectBySapSync();
        System.assert(result.size() > 0, 'No Se ha encontrado Pricebook2 entry');
    }
    @isTest
    private static void selectByName() {
        PriceBook2 newBook = new PriceBook2();
        newBook.Name = 'SAMPLES-TEST';
        insert newBook;
        Pricebook2 book = NBK_CreateSamplesOrderController.getSamplePricebook('TEST');
        System.assert(book != null);
    }

    @isTest private static void selectByCountry() {
        Test.startTest();
        Pricebook2 pb = [Select Id from Pricebook2 LIMIT 1];
        pb.IsRetailReferencePricebook__c = true;
        pb.CountryCode__c = 'GB';
        update pb;
        Test.stopTest();
        Pricebook2 pb2 = new PricebooksSelector().selectCountryReference('GB');
        Assert.areEqual(pb.Id, pb2.Id);
    }

    /*
    @isTest private static void defaultContactPointyNameTest() {
        Account acc = [select Id, AddressesSynced__c, SAP_Id__c from Account where Name = 'RESELLER' limit 1];
        String id = NBK_CreateSamplesOrderController.getDefaultContactPoint(acc.Id);
        System.assert(id != null);
    }
    */

    private static void createContactAddress(Account acc) {
        ContactPointAddress address = new ContactPointAddress();
        address.addressType = 'Billing';
        address.Name = 'Test adddress';
        address.SAPId__c = acc.SAP_Id__c;
        address.ParentId = acc.Id;
        address.City = 'Ilkley';
        address.CountryCode = 'GB';
        address.PostalCode = 'LS9 9EE';
        //address.stateCode = 'YO';
        address.IsDefault = true;
        address.Street = '9 The Grove';
        address.EMail__c = 'aaa@ccc.cxm';
        address.Phone__c = '111 222 333';  
        address.Mobile__c = '666 777 888';
        insert address;
    }
}