/**
* @author 		Ramón Prades
* @date 		April 2022
* @group 		Commons 
* @description 	Common methods for address management
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public class AddressCommons {

    /**
     * Returns a state/province code from the state name
     */
    public static String getProvinceCode(String countryCode, String provinceName) {
        String state = '';
        if (String.isNotBlank(provinceName)) {
            if (countryCode == 'US') {
                state = AddressCommons.getUSStateCode(provinceName);
            }  else if (countryCOde == 'CA') {
                state = AddressCommons.getCAStateCode(provinceName);
            }
        }
        return state;
    } // getProvinceCode

    /**
     * Builds a label forthe address (to use in a picklist)
     */
    public static String buildAddressLabel(String name, Address address) {
        return buildAddressLabel(name, address.street, address.postalCode, address.city, address.stateCode, address.countryCode);
    }

    /**
     * Builds a label for the address (to use in a picklist)
     */
    public static String buildAddressLabel(ContactPointAddress caddress) {
        return buildAddressLabel(caddress.name, caddress.street, caddress.postalCode, caddress.city, caddress.stateCode, caddress.countryCode);
    }

    /**
     * Builds a label forthe address (to use in a picklist)
     */
    public static String buildAddressLabel(String name, String street, string postalCode, String city, string stateCode, string countryCode) {
        String sep = '';
        String label;

        if (String.IsNotBlank(name)) {
            label = name.toUpperCase();
            sep = ', ';
        }

        if (String.isNotBlank(street)) {
            label += sep + street.capitalize();
            sep = ', ';
        }

        if (String.isNotBlank(city)) {
            label += sep + city.capitalize();
            sep = ', ';
        }

        if (countrycode == 'US' && String.IsNotBlank(statecode)) {
            label += ' (' + statecode + ') ';
            sep = ', ';
        }

        label += sep + countryCode;

        return label;
    } // buildPicklistLabel

    /**
     * Completes an address with the country and province names. Useful when SAP returns empty fields 
     * (or to set them in the user's language).
     */
    public static void completeAddressFields(ContactPointAddress addr) {
        if (addr.countryCode != null) {
            Map<String, Schema.PicklistEntry> countries = getCountries();
            Schema.PicklistEntry entry = countries.get(addr.countryCode);
            addr.country = entry.label;

            if (addr.stateCode != null) {
                Map<String, List<Schema.PicklistEntry>> allStates = getStates();
                for (PicklistEntry entry2 : allStates.get(addr.countryCode)) {
                    if (entry2.value == addr.stateCode) {
                        addr.state = entry2.label;
                        break;
                    }
                }
            }
        }
    } // completeAddressFields

    /**
     * Returns a MAP of countries
     */
    public static Map<String, Schema.PicklistEntry> getCountries() {
        Map<String, Schema.PicklistEntry> countries = new Map<String, Schema.PicklistEntry>();
        List<Schema.PicklistEntry> values = Contact.MailingCountryCode.getDescribe().getPickListValues();
        for (Schema.PicklistEntry v : values) {
            if (v.isActive()) {
                countries.put(v.getValue(), v);
            }
        }
        return countries;
    } // getCountries

    /**
     * Returns a MAP of countries with their list of states/provinces
     */
    public static Map<String, List<Schema.PicklistEntry>> getStates() {
        List<Schema.PicklistEntry> countries = Contact.MailingCountryCode.getDescribe().getPickListValues();
        List<Schema.PicklistEntry> counties = Contact.MailingStateCode.getDescribe().getPickListValues();
        Map<String, List<Schema.PicklistEntry>> results = new Map<String, List<Schema.PicklistEntry>>();        
        for (Schema.PicklistEntry county : counties) {
            if (county.isActive()) {
                String validFor = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(county))).get('validFor'));
                Integer countryIndex = getCountryIndex(validFor);
                Schema.PicklistEntry entry = countries[countryIndex];
                String countryCode = entry.getValue();        
                List<Schema.PicklistEntry> related = results.get(countryCode);
                if (related == null) {
                    related = new List<Schema.PicklistEntry>();
                    results.put(countryCode, related);
                }
                related.add(county);
            }
        }
        return results;
    } // getStates


    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private static String getUSStateCode(String stateName) {
        String state = '';
        switch on stateName.toLowerCase() {
            when 'alabama' { state = 'AL'; }
            when 'alaska' { state = 'AK'; }
            when 'arizona' { state = 'AZ'; }
            when 'arkansas' { state = 'AR'; }
            when 'california' { state = 'CA'; }
            when 'canal zone' { state = 'CZ'; }
            when 'colorado' { state = 'CO'; }
            when 'connecticut' { state = 'CT'; }
            when 'delaware' { state = 'DE'; }
            when 'district of columbia' { state = 'DC'; }
            when 'florida' { state = 'FL'; }
            when 'georgia' { state = 'GA'; }
            when 'guam' { state = 'GU'; }
            when 'hawaii' { state = 'HI'; }
            when 'idaho' { state = 'ID'; }
            when 'illinois' { state = 'IL'; }
            when 'indiana' { state = 'IN'; }
            when 'iowa' { state = 'IA'; }
            when 'kansas' { state = 'KS'; }
            when 'kentucky' { state = 'KY'; }
            when 'louisiana' { state = 'LA'; }
            when 'maine' { state = 'ME'; }
            when 'maryland' { state = 'MD'; }
            when 'massachusetts' { state = 'MA'; }
            when 'michigan' { state = 'MI'; }
            when 'minnesota' { state = 'MN'; }
            when 'mississippi' { state = 'MS'; }
            when 'missouri' { state = 'MO'; }
            when 'montana' { state = 'MT'; }
            when 'nebraska' { state = 'NE'; }
            when 'nevada' { state = 'NV'; }
            when 'new hampshire' { state = 'NH'; }
            when 'new jersey' { state = 'NJ'; }
            when 'new mexico' { state = 'NM'; }
            when 'new york' { state = 'NY'; }
            when 'north carolina' { state = 'NC'; }
            when 'north dakota' { state = 'ND'; }
            when 'ohio' { state = 'OH'; }
            when 'oklahoma' { state = 'OK'; }
            when 'oregon' { state = 'OR'; }
            when 'pennsylvania' { state = 'PA'; }
            when 'puerto rico' { state = 'PR'; }
            when 'rhode island' { state = 'RI'; }
            when 'south carolina' { state = 'SC'; }
            when 'south dakota' { state = 'SD'; }
            when 'tennessee' { state = 'TN'; }
            when 'texas' { state = 'TX'; }
            when 'utah' { state = 'UT'; }
            when 'vermont' { state = 'VT'; }
            when 'virgin islands' { state = 'VI'; }
            when 'virginia' { state = 'VA'; }
            when 'washington' { state = 'WA'; }
            when 'west virginia' { state = 'WV'; }
            when 'wisconsin' { state = 'WI'; }
            when 'wyoming' { state = 'WY'; }            
        }
        return state;
    }

    private static String getCAStateCode(String state) {
        String xState = state.toLowerCase();
        switch on xState {
            when 'alberta' { return 'AB'; }
            when 'british columbia' { return 'BC'; }
            when 'manitoba' { return 'MB'; }
            when 'new brunswick' { return 'NB'; }
            when 'newfoundland and labrador' { return 'NL'; }
            when 'Nova Scotia' { return 'NS'; }
            when 'northwest territories' { return 'NT'; }
            when 'nunavut' { return 'NU'; }
            when 'ontario' { return 'ON'; }
            when 'prince edward island' { return 'PE'; }
            when 'quebec' { return 'QC'; }
            when 'saskatchewan' { return 'SK'; }
            when 'yukon' { return 'YT'; }    
            when else { return '';}
        }    
    }

    private static Integer getCountryIndex(String validFor) {
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        List<String> chars = validFor.split('');
        String binString = '';
        for (String ch : chars) {
            Integer i = base64map.indexOf(ch);
            String bin = intToBinary(i);
            bin = bin.leftPad(6, '0');
            binString += bin;
        }
        return binString.indexOf('1');
    }
    
    private static String intToBinary(Integer n) {
        String s = '';
        while(n != 0) {
            s = (n & 1) + s;
            n >>>= 1;
        }
        return s;
    }

} // class