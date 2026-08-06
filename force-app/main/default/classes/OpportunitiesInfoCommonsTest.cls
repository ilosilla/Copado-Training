@isTest public class OpportunitiesInfoCommonsTest {
    @testSetup private static void testSetup() {
        Opportunity[] opps = DataFactoryOpportunity.createTradeOpportunities(2, 10);
    }

    @isTest static void setOpportunityType() {
        Opportunity[] opps = [select Id, InfoType__c from Opportunity limit 5];
        List<Id> ids = TypeConversionCommons.extractListOfIds(opps);
        OpportunitiesInfoCommons.setOpportunityType(ids, OpportunitiesInfoCommons.KITCHEN_TYPE);
        Opportunity[] opps2 = [select Id, InfoType__c from Opportunity where InfoType__c = :OpportunitiesInfoCommons.KITCHEN_TYPE];
        System.assertEquals(opps.size(), opps2.size(), 'Number of opportunities updated does not match');
    }
}