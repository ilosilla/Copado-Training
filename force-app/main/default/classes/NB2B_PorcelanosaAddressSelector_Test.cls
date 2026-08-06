@IsTest
public class NB2B_PorcelanosaAddressSelector_Test {

    @IsTest
    public static void test(){

        NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(40.13123, -21.2,10,'US','FL');
        NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(40.13123, -21.2,10,'FR','FL');
        NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(40.13123, -21.2, 'US','FL');
        NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(40.13123, -21.2, 'FR','FL');
        NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(40.13123, -21.2, new List<String>{'US'});
        NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(40.13123, -21.2, new List<String>{'FR'});
        NB2B_PorcelanosaAddressSelector.getStoresNearCityUS('FL', new List<String>{'US'});
        NB2B_PorcelanosaAddressSelector.getStoresNearCountryUS( new List<String>{'US'});
    }

}