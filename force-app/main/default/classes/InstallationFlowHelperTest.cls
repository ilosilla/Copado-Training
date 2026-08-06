@isTest
private class InstallationFlowHelperTest {
    
     @testSetup static void setup() {
		TestUtils.enableTriggers();
     }
    
    @isTest static void test_getInstallers_B() {   
        DataFactoryAccount.autoInsert = true;    
        
        User user = DataFactoryUser.createUKUsers(1)[0];
        user.Sales_Org__c = OrganizationCommons.ORG_NORTH_WEST;

        List<Account> accounts = DataFactoryAccount.createPersonAccounts(1);
        Opportunity opp  = DataFactoryOpportunity.createRetailOpportunities(accounts, 1)[0];   
		    opp.countryCode__c = 'GB';
        opp.Postcode__c = 'LS9 9EE';
        opp.OwnerId = user.Id;
        update opp;

        List<Installer__c> ins = new List<Installer__c>();
        Account[] accs = DataFactoryAccount.createAccounts(2);
        Account acc1 = accs[0];
        Account acc2 = accs[1];
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_SOUTH_EAST, Account__c = acc1.Id));
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_NORTH_WEST, Account__c = acc1.Id));
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_NORTH_WEST, Account__c = acc2.Id));
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_YORKSHIRE, Account__c = acc2.Id));
        insert ins;
        
        List<String> opps = new List<String>();
        opps.add(opp.id);
        List<FlowListType> results = InstallationFlowHelper.getInstallers(opps);
        System.assertEquals(2, results[0].size, 'One installer should have been found');
    }        

}