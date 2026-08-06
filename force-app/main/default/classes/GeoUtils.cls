/**
* @author 		Ramón Prades
* @date 		January 2022
* @group 		Utils
* @description 	Geographical utility methods
*/
public class GeoUtils {

    /**
     * Checks if the state passed is teh dummy code used in SAP (01)
     */
    public static Boolean isDummyStateCode(String countryCode, String stateCode) {
        Boolean isDummy = false;
        if (stateCode == '01') {
            if (countryCode == 'GB' || countryCode == 'US' || countryCode == 'CA' ) {
                isDummy = true;
            }
        }
        return isDummy;
    } // isDummyStateCode

    public static String getUSStateCode(String state) {
        return AddressCommons.getProvinceCode('US', state);
    }

    public static String getCAStateCode(String state) {
        return AddressCommons.getProvinceCode('CA', state);
    }
    
}