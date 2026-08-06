@isTest public with sharing class InternationalAddressTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryOpportunity.autoInsert = false;
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(1, 2);
        opps[0].Address__c = '7 Boroline Road';
        opps[0].City__c = 'Saddle River';
        opps[0].PostCode__c = '07770';
        opps[0].CountryCode__c = 'US';

        opps[1].Address__c = '7 Boroline Road';
        opps[1].City__c = 'Leeds';
        opps[1].PostCode__c = 'LS9 9EE';
        opps[1].CountryCode__c = 'GB';

        insert opps;        
    }

    @isTest private static void testUSAddress() {
        Opportunity opp = [select Id, CountryCode__c from Opportunity where CountryCode__c = 'US' limit 1];
        InternationalAddress addr = InternationalAddress.fromOpportunity(opp.Id);
        String a = addr.format();
        System.assertNotEquals(0, a.length(), 'No US formatted address returned');
    }

    @isTest private static void testGBAddress() {
        Opportunity opp = [select Id, CountryCode__c from Opportunity where CountryCode__c = 'GB' limit 1];
        InternationalAddress addr = InternationalAddress.fromOpportunity(opp.Id);
        String a = addr.format();
        System.assertNotEquals(0, a.length(), 'No GB formatted address returned');
    }

}