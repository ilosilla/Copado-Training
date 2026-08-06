@isTest public class LibAddressCommonsControllerTest {

    @testSetup private static void testSetup() {
        DataFactoryPorcelanosaAddress.createAddresses();
    }

    @isTest private static void testGetPorcelansoaAddress() {
        PorcelanosaAddress__c pid = [select Id from PorcelanosaAddress__c limit 1];
        PorcelanosaAddress__c o = LibAddressCommonsController.getPorcelanosaAddress(pid.Id);
        Assert.areEqual(pid.id, o.Id, 'Address Ids should match');
    }

}