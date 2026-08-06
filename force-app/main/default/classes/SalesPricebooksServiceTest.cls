/**
 * @author         Ramón Prades
 * @date           June 2024
 * @layer          Services
 * @description    Test class
*/
@isTest public class SalesPricebooksServiceTest {

    @testSetup public static void testSetup() {   
        Sales_Org__c sorg = new Sales_Org__c();     
        sorg.Name = 'Test SORG';
        sorg.CountryCode__c = 'US';
        sorg.SalesOrg__c = '610';
        insert sorg;

        Pricebook2 pb = new Pricebook2();
        pb.Name = 'Test Pricebook';
        pb.isActive = true;
        pb.SapSync__c = true;
        pb.CurrencyIsoCode = 'USD';
        pb.PriceType__c = 'UPR';
        pb.IsRetailReferencePricebook__c = true;
        pb.CountryCode__c = 'US';

        if (Test.isRunningTest()) {
            insert pb;
        }
    } // testSetup

    @isTest private static void testStandardOrder() {
        Order o = new Order();
        o.Type = SalesPricebooksService.ORDER_STANDARD_TYPE;
        o.SalesOrg__c = '610';
         
        Pricebook2 dbBook = [select Id from Pricebook2 limit 1];
        Pricebook2[] result = SalesPricebooksService.getOrderPricebooks(o);
        Assert.areEqual(1, result.size(), 'A result is expected');
        Assert.areEqual(dbBook.Id, result[0].Id, 'Wrong pricebook');
   }

   @isTest private static void testClaimsOrder() {
        Order o = new Order();
        o.Type = SalesPricebooksService.ORDER_REPLACEMENT_TYPE;
        o.CurrencyIsoCode = 'USD';
        o.SalesOrg__c = '610';

        Pricebook2 dbBook = [select Id from Pricebook2 limit 1];
        dbBook.IsForClaims__c = true;
        dbBook.CurrencyIsoCode = 'USD';
        update dbBook;

        Pricebook2[] result = SalesPricebooksService.getOrderPricebooks(o);
        Assert.areEqual(1, result.size(), 'A result is expected');
        Assert.areEqual(dbBook.Id, result[0].Id, 'Wrong pricebook');
    }

    @isTest private static void testWrongCurrency() {
        Order o = new Order();
        o.Type = SalesPricebooksService.ORDER_REPLACEMENT_TYPE;
        o.CurrencyIsoCode = 'GBP';
        o.SalesOrg__c = '610';

        Pricebook2 dbBook = [select Id from Pricebook2 limit 1];
        dbBook.IsForClaims__c = true;
        dbBook.CurrencyIsoCode = 'USD';
        update dbBook;

        Pricebook2[] result = SalesPricebooksService.getOrderPricebooks(o);
        Assert.areEqual(0, result.size(), 'No results expected');
    }

}