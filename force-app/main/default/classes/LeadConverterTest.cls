@isTest public class LeadConverterTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
    }

    @isTest public static void testConvertRetailOpportunity() {
        Lead lead = getUSRetailLead();
        LeadConverter converter = new LeadConverter(lead.Id);
        converter.setNewOpportunityFlag(true, 'Test Opp');
        Database.LeadConvertResult result = converter.convert();        
        System.assertEquals(true, result.isSuccess(), 'Conversion should have been a success');
        System.assertNotEquals(null, result.getAccountId(), 'The conversion should have created an account');
        System.assertNotEquals(null, result.opportunityid, 'The conversion should have created an opportunity');
        Account acc = [select Id, isPersonAccount, PersonContactId from Account where id = :result.getAccountId() limit 1];
        System.assertEquals(true, acc.isPersonAccount, 'The account created should have been a person account');
        System.assertNotEquals(null, acc.PersonContactId, 'The account created should have been a contact Id');
    }    

    @isTest public static void testConvertTrade() {
        Lead lead = getUSTradeLead();
        addItems(lead);
        LeadConverter converter = new LeadConverter(lead.Id);
        converter.setNewOpportunityFlag(true, 'Test Trade Opp');      
        converter.setConvertProductsFlag(true, true);
        Database.LeadConvertResult result = converter.convert();  
        System.assertEquals(true, result.isSuccess(), 'Conversion should have been a success');
        System.assertNotEquals(null, result.getAccountId(), 'The conversion should have created an account');
        System.assertNotEquals(null, result.getContactId(), 'The conversion should have created a contact');
        System.assertNotEquals(null, result.opportunityid, 'The conversion should have created an opportunity');
        
        Account acc = [select Id, isPersonAccount from Account where id = :result.getAccountId() limit 1];
        System.assertEquals(false, acc.isPersonAccount, 'The account created should have been a trade account');    

        OpportunityLineItem[] items = [select Id from OpportunityLineItem where opportunityId = :result.getOpportunityId()];
        System.assertNotEquals(0, items.size(), 'The lead product list should have been converted to Opportunity Line Items');    

    }   
    
    @isTest public static void testConvertTrade_2() {
        Lead lead = getUSTradeLead();
        LeadConverter converter = new LeadConverter(lead.Id);
        Database.LeadConvertResult result = converter.convert();

        Lead lead2 = getUSRetailLead();
        LeadConverter converter2 = new LeadConverter(lead2.Id);
        converter2.setAccountId(result.getAccountId());
        converter2.setContactId(result.getContactId());
        converter2.setOpportunityId(result.getOpportunityId());
        try {
            Database.LeadConvertResult result2 = converter2.convert();        
            System.assertEquals(result.getAccountId(), result2.getAccountId(), 'Second lead should have been assigned to the account in lead 1');
            System.assertEquals(result.getOpportunityId(), result2.getOpportunityId(), 'Second lead should have been assigned to the opportunity in lead 1');
        } catch (Exception ex) {
            System.debug('RPR' + ex.getMessage());
        }
    }


    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private static Lead getUSRetailLead() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createUSWebRequest(1)[0];        
        l.Opportunity_Name__c = 'This is the opportunity title';
        l.Company = '';
        l.Address__c = '7 Boroline Road';
        l.CountryCode__c = 'US';
        l.State__c = 'CA';
        l.City__c = 'Upper Saddle River';
        l.Postcode__c = '07770';
        l.State__c = 'NJ';
        l.MobilePhone = '333 666 333';
        l.Operation_Type__c = 'Refurbishment';
        l.Close_Date__c = System.today();
        l.firstName = 'John';
        l.lastName = 'Murray';
        l.Email = 'jmurray@gmailx.xom';
        l.CurrencyIsoCode = 'USD';
        insert l;
        return l;        
    }

    private static Lead getUSTradeLead() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createUSWebRequest(1)[0];        
        l.CurrencyIsoCode = 'USD';
        l.Opportunity_Name__c = 'This is the opportunity title';
        l.Company = 'ACME Company';
        l.Title = 'Senior Architect';
        l.Address__c = '7 Boroline Road';
        l.CountryCode__c = 'US';
        l.State__c = 'CA';
        l.City__c = 'Upper Saddle River';
        l.State__c = 'NJ';
        l.Postcode__c = '07770';
        l.MobilePhone = '333 666 333';
        l.Operation_Type__c = 'Refurbishment';
        l.Close_Date__c = System.today();
        l.firstName = 'John';
        l.lastName = 'Murray';
        l.Email = 'jmurray@gmailx.xom';
        l.CurrencyIsoCode = 'USD';
        insert l;
        return l;        
    }

    private static void addItems(Lead lead) {
        Pricebook2 pb = DataFactoryProduct.createPricebook();
        SystemSettings.materialBankPricebook = pb.Id;
        SystemSettings.DummyProduct = DataFactoryProduct.DummyProductCode;
        Product2[] products = DataFactoryProduct.createProducts(pb);
        ProductListItem__c[] items = new List<ProductListItem__c>();
        items.add(createItem(lead, products[0]));
        items.add(createItem(lead, products[1]));
        items.add(createItem(lead, products[2]));
        items.add(createDummy(lead));
        insert items;
    }

    private static ProductListItem__c createItem(Lead lead, Product2 product) {
        ProductListItem__c item = new ProductListItem__c();
        item.CurrencyIsoCode = lead.CurrencyIsoCode;
        item.isSample__c = true;
        item.Lead__c = lead.Id;
        item.ProductCode__c = product.ProductCode;
        item.Name__c = product.Name;
        item.Quantity__c = 1;
        item.Unit__c = 'PZS';
        return item;
    }

    private static ProductListItem__c createDummy(Lead lead) {
        ProductListItem__c item = new ProductListItem__c();
        item.CurrencyIsoCode = lead.CurrencyIsoCode;
        item.isSample__c = true;
        item.Lead__c = lead.Id;
        item.ProductCode__c = 'A14';
        item.Name__c = 'THIS CODE DOES NOT EXIST SO USE DUMMY';
        item.Quantity__c = 1;
        item.Unit__c = 'PZS';
        return item;
    }

}