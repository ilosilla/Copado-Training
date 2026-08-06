@isTest public with sharing class AddressCommonsTest {
    @isTest public static void testGetProvinceCodeUS() {
        System.assertEquals('NJ', AddressCommons.getProvinceCode('US', 'New Jersey'));
        System.assertEquals('', AddressCommons.getProvinceCode('US', 'Almassora'));
    }
    @isTest public static void testGetProvinceCodeCA() {
        System.assertEquals('AB', AddressCommons.getProvinceCode('CA', 'Alberta'));
        System.assertEquals('', AddressCommons.getProvinceCode('CA', 'Bechí'));
    }

    @isTest public static void testPicklistLabel() {
        DataFactoryContactPointAddresses.createUSRecords(5);
        ContactPointAddress adr = [select Id, Address from ContactPointAddress limit 1];
        String label = AddressCommons.buildAddressLabel('the name', adr.address);
        Assert.isNotNull(label, 'Label should not be blank');
    }

    @isTest public static void testGetCountries() {
        Map<String, Schema.PicklistEntry> countries = AddressCommons.getCountries();
        String spain = countries.get('ES').getValue();
        Assert.isNotNull(spain, 'Countries seem to be empty');
    }

    @isTest public static void testGetStates() {
        Map<String, List<Schema.PicklistEntry>> states = AddressCommons.getStates();
        List<Schema.PicklistEntry> provincias = states.get('ES');
        Assert.isTrue(provincias.size() > 0, 'States returned seem wrong');
    }

    @isTest public static void testCompleteAddressFields() {
        DataFactoryContactPointAddresses.createUSRecords(5);
        ContactPointAddress adr = [select Id, Address, Country, CountryCode, State, StateCode from ContactPointAddress limit 1];
        adr.State = null;
        adr.Country = null;
        AddressCommons.completeAddressFields(adr);
        Assert.isNotNull(adr.Country, 'Country name missing');
        Assert.isNotNull(adr.State, 'State should not be empty');
    }


}