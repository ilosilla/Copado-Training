@isTest public class AddressFormatterTest {

    @isTest private static void testFormatUS() {
        AddressDTO address = new AddressDTO();
        address.country = 'United States';
        address.countryCode = 'US';
        address.street = '123 4th Street\nApartment #20';
        address.city = 'Seattle';
        address.postCode = '98101';
        address.state = 'Washington';
        address.stateCode = 'WA';

        AddressFormatter formatter = new AddressFormatter(address);
        String[] lines = formatter.format();
        Assert.areEqual(4, lines.size(), 'The address should be 4 lines long');

        String formattedAddress = formatter.formatAsString();
        Assert.isNotNull(formattedAddress, 'Formatted address should not be null');
    }
    @isTest private static void testFormatGB() {
        AddressDTO address = new AddressDTO();
        address.country = '';
        address.countryCode = 'GB';
        address.street = '9 High Street\nBushey';
        address.city = 'Watford';
        address.postCode = 'W9 9EE';
        address.state = 'Sussex';

        AddressFormatter formatter = new AddressFormatter(address);
        String[] lines = formatter.format();
        Assert.areEqual(4, lines.size(), 'The address should be 4 lines long');

        String formattedAddress = formatter.formatAsHTML();
        Assert.isNotNull(formattedAddress, 'Formatted address should not be null');
    }

    @isTest private static void testFormatES() {
        AddressDTO address = new AddressDTO();
        address.country = 'Spain';
        address.countryCode = 'ES';
        address.street = 'Avenida Portugal 45';
        address.city = 'Palencia';
        address.postCode = '41455';

        AddressFormatter formatter = new AddressFormatter(address);
        String[] lines = formatter.format();
        Assert.areEqual(3, lines.size(), 'The address should be 3 lines long');

        String formattedAddress = formatter.formatAsHTML();
        Assert.isNotNull(formattedAddress, 'Formatted address should not be null');
    }
            
}