/**
 * Test class
 * Ramón
 * October 2020
*/
@isTest public class AddressDTOTest {
    @TestSetup
    static void setup() {
        TestUtils.enableTriggers();        
    }

    @isTest private static void readFromAccount() {
        Account person = DataFactoryAccount.createPersonAccounts(1)[0];
        AddressDTO personAddress = AddressDTO.readFromAccount(person.Id);

        Account business  = DataFactoryAccount.createBusinessAccounts(1)[0];
        AddressDTO bussinessAddress = AddressDTO.readFromAccount(business.Id);

        System.assertNotEquals(null, personAddress.countryCode);
        System.assertNotEquals(null, bussinessAddress.countryCode);

    }

    @isTest private static void readFromContactPoint() {
        List<ContactPointAddress> addrs = DataFactoryContactPointAddresses.createRecords(1, 10);
        AddressDTO dto = AddressDTO.readContactPointAddress(addrs[0].Id);
        Assert.isNotNull(dto, 'An address should have been read');
    }

    @isTest private static void convertToAddress() {
        List<ContactPointAddress> addrs = DataFactoryContactPointAddresses.createRecords(1, 10);
        AddressDTO dto = AddressDTO.readContactPointAddress(addrs[0].Id);
        Schema.Address addr = dto.toAddress();
        Assert.areEqual(dto.city, addr.City, 'City should match');
    }

    @isTest private static void readFromPorcelanosaAddress() {
        PorcelanosaAddress__c[] porsas = DataFactoryPorcelanosaAddress.createAddresses();
        Id porId = null;
        for (PorcelanosaAddress__c p : porsas) {
            if (p.SAPSalesOrg__c == '605') {
                porId = p.Id;
                break;
            }
        }
        Assert.isNotNull(porId, 'A Porcelanosa address for sales org 605 should exist in test data');   
        PorcelanosaAddress__c porsa = (PorcelanosaAddress__c) new PorcelanosaAddressesSelector().selectById(new Set<Id>{porId})[0];
        AddressDTO dto = AddressDTO.readPorcelanosaAddress(porsa);
        Assert.isNotNull(dto, 'An address should have been read from PorcelanosaAddress__c');
        Assert.areEqual('NY', dto.stateCode, 'The state code should be NY');
        Assert.areEqual('NEW YORK', dto.state?.toUpperCase(), 'The state name should be NEW YORK');
        Assert.areEqual('US', dto.countryCode, 'The country code should be US');
    }

    @isTest private static void readFromOrderDeliveryGroup() {
        Order o = DataFactoryOrder.createOrders(1)[0];
        AddressDTO dto = AddressDTO.readFromOrderDeliveryGroup(o.Id);
        Assert.isNotNull(dto, 'Expected non-null DTO');
    }


}