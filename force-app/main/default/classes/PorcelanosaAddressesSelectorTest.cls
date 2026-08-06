@isTest public class PorcelanosaAddressesSelectorTest {

    @testSetup private static void testSetup() {
        DataFactoryPorcelanosaAddress.createAddresses();
    }

    @isTest private static void  testSelectAll() {
        List<SObject> all = new PorcelanosaAddressesSelector().selectAll();
        Assert.isTrue(all.size() > 0,  'There should be at least an address');
    }

    @isTest private static void  testSelectByCountry() {
        Set<String> ccodes = new Set<String>();
        ccodes.add('US');
        List<SObject> us = new PorcelanosaAddressesSelector().selectByCountry(ccodes);
        Integer nus = us.size();
        Assert.isTrue(nus > 0,  'There should be at least an US address');

        ccodes.add('GB');
        List<SObject> usAndGb = new PorcelanosaAddressesSelector().selectByCountry(ccodes);
        Assert.isTrue(usAndGb.size() > nus ,  'There should be more addresses than in the US only');
    }

    @isTest private static void testSelectBySalesOrg() {
        Set<String> orgs = new Set<String>{'502', '605'};
        List<PorcelanosaAddress__c> addrs = new PorcelanosaAddressesSelector().selectBySalesOrg(orgs);
        Assert.isTrue(addrs.size() > 0, 'There should be at least one address');
    }

    @isTest private static void testSCollectionPoints() {
        Set<String> orgs = new Set<String>{'502', '605'};
        List<PorcelanosaAddress__c> addrs = new PorcelanosaAddressesSelector().selectCollectionPoints(orgs);
        Assert.isTrue(addrs.size() > 0, 'There should be at least one address');
    }

}