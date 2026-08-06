//TEst class
@isTest public class ECommerceOpportunityTest {
    
    @TestSetup private static void makeData() {
        TestUtils.enableTriggers();
        
        Master_relations__c master = new Master_relations__c();
        master.DistributionChannel_code__c = '60';
        master.SalesOffice_code__c = '2554';
        master.SalesOrg_code__c = OrganizationCommons.ORG_SOUTH_EAST;
        insert master;

        User testUser = User_TestDataFactory.createUsersNoAdmin(1, new List<String>{'en_US'})[0];
        testUser.Sales_Org__c = OrganizationCommons.ORG_NORTH_WEST + ';' + OrganizationCommons.ORG_SOUTH_EAST;
        testUser.Default_Sales_Organization__c = OrganizationCommons.ORG_SOUTH_EAST;
        testUser.Distribution_channel__c = '60';
        testUser.Distribution_channel_default__c = '60';
        testUser.Sales_Office__c = '2554';
        testUser.Does_this_position_have_a_sales_budget__c = 'Si';
        Insert testUser;
    }

    @isTest private static void getpportunity_GB() {
        Account account = DataFactoryAccount.createPersonAccounts(1)[0];
        User genericUser = TestUtils.getGenericUser();
        account.OwnerId = genericUser.Id; // Assigned to generic user to test if the owner is fixed
        update account;
        Order order = new Order(
            AccountId = account.Id,
            Sap_Id__c = '0012345678',
            SalesOrg__c = OrganizationCommons.ORG_SOUTH_EAST,
            SalesOffice__c = '2554',
            Status = 'Draft',
            EffectiveDate = System.today()
        );
        ECommerceOpportunity eco = new ECommerceOpportunity(order);        
        Opportunity opp = eco.getOpportunity();
        System.assertEquals(account.Id, opp.AccountId); // Opportunity created
        // System.assertNotEquals(genericUser.Id, opp.OwnerId);
    }
} // class