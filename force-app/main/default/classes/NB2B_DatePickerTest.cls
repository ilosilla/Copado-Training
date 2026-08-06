@isTest
public class NB2B_DatePickerTest {

    @isTest
    static void testGetb2bMetadataValidCountry() {
        String country = 'United Kingdom';
        List<B2B_Country_Settings__mdt> result = NB2B_DatePicker.getb2bMetadata(country);
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testGetb2bMetadataInvalidCountry() {
        String invalidCountry = 'Sweeden';
        List<B2B_Country_Settings__mdt> result = NB2B_DatePicker.getb2bMetadata(invalidCountry);
        System.assertEquals(0, result.size());
    }

}