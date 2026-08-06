@isTest public with sharing class ECommerceUtilsTest {

    @testSetup private static void setup() {
        TestUtils.enableTriggers();        
    }

    @isTest private static void findOpportunity() {
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1,1)[0];
        String sapOrder = '0012345678';
        opp.SAP_Order__c = sapOrder;
        update opp;

        Id id = ECommerceUtils.findOpportunity(sapOrder);
        System.assertNotEquals(null, id);

        id = ECommerceUtils.findOpportunity('1111112221');
        System.assertEquals(null, id);

    } // findOpportunity


    private static void createOrder(String sapOrder) {
        Account account = DataFactoryAccount.createPersonAccounts(1)[0];
        Order order = new Order(
            AccountId = account.Id,
            Sap_Id__c = sapOrder,
            SalesOrg__c = OrganizationCommons.ORG_SOUTH_EAST,
            SalesOffice__c = '2554',
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        insert order;
    } // createOrder
} // class