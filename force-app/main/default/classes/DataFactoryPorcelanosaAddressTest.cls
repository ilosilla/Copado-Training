@isTest public class DataFactoryPorcelanosaAddressTest {
    @testSetup private static void testSetup() {
        DataFactoryPorcelanosaAddress.createAddresses();
    }

    @isTest private static void testCreate() {
        List<PorcelanosaAddress__c> addr = [select Id from PorcelanosaAddress__c];
        Assert.isTrue(addr.size() > 0, 'There should be at least one record');
    }
}