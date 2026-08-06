/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Commons
* @description 	Utility methods to work with picklists
*/
public class PicklistCommons {

    /**
     * Checks if a string is a valid picklist value
     */
    public static Boolean isPicklistValue(Schema.SObjectField field, String value) {
        Map<String, String> pvalues = getValues(field);
        return pvalues.containsKey(value);
    }
    
    /**
     * Gets a list of a picklist keys
     */
    public static List<String> getKeysList(Schema.sObjectField field) {
        List<String> keys = new List<String>();
        List<Schema.PicklistEntry> entries = ReflectionUtils.getPicklistValues(field);
        for (Schema.PicklistEntry entry : entries) {
            keys.add(entry.getValue());
        }
        return keys;
    }

    /**
     * Gets the map (value, label) of a picklist field (all active fields regardless of the record type)
     */
    public static Map<String, String> getValues(Schema.sObjectField field) {
        Map<String, String> result = new Map<String,String>();
        List<Schema.PicklistEntry> entries = ReflectionUtils.getPicklistValues(field);
        for (Schema.PicklistEntry entry : entries) {
            result.put(entry.getValue(), entry.getLabel());
        }
        return result;
    } // getPicklistValuesMap

    /**
     * Gets the map (label, value) of a picklist field (all active fields regardless of the record type)
     */
    public static Map<String, String> getValuesSwaped(Schema.sObjectField field) {
        Map<String, String> result = new Map<String,String>();
        List<Schema.PicklistEntry> entries = ReflectionUtils.getPicklistValues(field);
        for (Schema.PicklistEntry entry : entries) {
            result.put(entry.getLabel(), entry.getValue());
        }
        return result;
    } // getValuesSwaped

    /**
     * Gets the map (value in uppercase, value) of a picklist 
     */
    public static Map<String, String> getUpperCaseKeys(Schema.sObjectField field) {
        Map<String, String> result = new Map<String,String>();
        List<Schema.PicklistEntry> entries = ReflectionUtils.getPicklistValues(field);
        for (Schema.PicklistEntry entry : entries) {
            result.put(entry.getValue().toUpperCase(), entry.getValue());
        }
        return result;
    } // getPicklistValuesMap


    /**
     *  Validates the list of picklist options and returns the valid ones only
     */
    public static List<String> validatePicklistValues(Schema.sObjectField field, List<String> picks) {
        Map<String, String> options = PicklistCommons.getUpperCaseKeys(field);
        List<String> result = new List<String>();
        for (String pick : picks) {
            pick = pick.trim();
            if (String.isNotEmpty(pick)) {
                String option = options.get(pick.toUpperCase());
                if (option!= null) {
                    result.add(option);
                }
            }
        }
        return result;
    }

}