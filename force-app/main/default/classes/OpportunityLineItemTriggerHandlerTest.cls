@isTest
public class OpportunityLineItemTriggerHandlerTest {
    @testSetup
    static void setup(){
        TestUtils.enableTriggers();
        Account accCustomer = Account_TestDataFactory.createCustomer();
        Insert accCustomer;
        Insert Account_TestDataFactory.createBusinessAccount();
        
        List<Product2> products = DataFactoryProduct.createProducts();
        
        Map<String, Object> fieldsToAdd = new Map<String, Object>();
        fieldsToAdd.put('Sales_Org__c', OrganizationCommons.ORG_AZURCERAMIQUE);
        fieldsToAdd.put('Dist_Channel__c', '10');
        fieldsToAdd.put('AccountId', accCustomer.Id);
        
        Opportunity opp1 = Opportunity_TestDataFactory.createOpportunities(1, fieldsToAdd)[0];
        // opp1.Pricebook2Id = entryPriceBook[0].Pricebook2Id;
        opp1.Currency__c = 'USD';
        insert opp1;
        List<PricebookEntry> entryPriceBook = [select id, CurrencyIsoCode, Pricebook2Id  from PricebookEntry where Product2Id =: products[0].Id and currencyIsoCode = 'USD'];

        opp1.Pricebook2Id = entryPriceBook[0].Pricebook2Id;
        update opp1;
        
        
        
        OppPriceRequestHeader__c priceRequestHeader = new OppPriceRequestHeader__c(Neededby__c = Date.newInstance(2021, 8, 17), currencyIsoCode = 'USD', Opportunity__c = opp1.Id);
        insert priceRequestHeader;
        
        Opportunity opp = new OpportunitiesSelector().selectById(opp1.Id);
        
        entryPriceBook = [select id, currencyIsoCode, Pricebook2Id  from PricebookEntry where currencyIsoCode = 'USD' and Pricebook2Id =: opp.Pricebook2Id];

        OpportunityLineItem newItem = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = products[0].Id, PricebookEntryId = entryPriceBook[0].Id ,Quantity = 4, UnitPrice = 334);
        insert newItem;
        OpportunityLineItem newItem2 = new OpportunityLineItem(OpportunityId = opp.Id, Product2Id = products[1].Id, PricebookEntryId = entryPriceBook[0].Id ,Quantity = 4, UnitPrice = 334);
        insert newItem2;
        OppPriceRequestItem__c item = new OppPriceRequestItem__c(OpportunityProduct__c= newItem2.Id,Status__c = 'PENDING', ProductCode__c = '1111111', ProductName__c = 'TTTTT', PromoFactoryPrice__c = 34.45, currencyIsoCode = 'USD', priceRequestHeader__c = priceRequestHeader.Id);
        insert item;
        OppPriceRequestItem__c item2 = new OppPriceRequestItem__c(OpportunityProduct__c= newItem.Id,ProductCode__c = '1111111', ProductName__c = 'TTTTT', PromoFactoryPrice__c = 34.45, currencyIsoCode = 'USD', priceRequestHeader__c = priceRequestHeader.Id);
        insert item2;
    }
    
    @isTest
    public static void deleteItems(){
        OpportunityLineItem oppItem = [SELECT id from OpportunityLineItem where id IN (select OpportunityProduct__c from OppPriceRequestItem__c where status__c <> 'PENDING')];
        OpportunityLineItem oppItem2 = [SELECT id from OpportunityLineItem where id IN (select OpportunityProduct__c from OppPriceRequestItem__c where status__c = 'PENDING')];

        delete oppItem;
        
        List<OpportunityLineItem> oppItems = [SELECT id from OpportunityLineItem where id IN (select OpportunityProduct__c from OppPriceRequestItem__c where status__c <> 'PENDING')];
        System.assertEquals(0, oppItems.size(), 'No se ha eliminado el Item');

        List<Database.DeleteResult> results = database.delete(new List<OpportunityLineItem>{oppItem2}, false);

        for (Database.DeleteResult result : results) {
            System.assertEquals(result.isSuccess(), false, 'No ha fallado el delete');
        }
    }
}