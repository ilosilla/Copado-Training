/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Commons
* @description 	Type converssion methods
*/
public class TypeConversionCommons {
    
    /**
     * Extracts a list of IDs from a list of objects
     */
    public static List<Id> extractListOfIds(List<SObject> objects) {
        List<Id> ids = new List<Id>();
        for (SObject obj :objects) {
            ids.add(obj.Id);
        }
        return ids;
    }

    /**
     * Extracts the values of a specified field from a list of sObjects.
     */
    public static List<String> extractFieldValues(List<sObject> records, String fieldName) {
        List<String> values = new List<String>();        
        for (sObject record : records) {
            values.add(String.valueOf(record?.get(fieldName)));
        }        
        return values;
    }
    
    /**
     * Converts a List of any sObject in a set of Ids
     */
    public static Set<Id> listToSet(List<SObject> objects) {
        Set<Id> result = new Set<Id>();
        for (SObject o : objects) {
            if (!result.contains(o.Id)) {
                result.add(o.Id);
            }
        }
        return result;
    } // listToSet

        /**
     * Converts a List of any sObject in a set of a given property
     */
    public static Set<String> listToSet(List<SObject> objects, String propertyName) {
        Set<String> result = new Set<String>();
        for (SObject o : objects) {
            result.add(String.valueOf(o.get(propertyName)));
        }
        return result;
    } // listToSet

    /**
	 * Returns a Map that indexes a list of SObjects by the specified property name.
     * The property is converted to a string.
	 * Records with null property values are excluded.
     * "toUpperCase" converts the index to upper case.
    */
    public static Map<String, SObject> listToMap(List<SObject> records, String propertyName, Boolean toUpperCase) {
        // Create the resulting Map
        Map<String, SObject> resultMap = new Map<String, SObject>();
        for (SObject record : records) {
            // Get the value of the specified property dynamically
            Object key = record.get(propertyName);
            if (key != null) {
                String skey = String.valueOf(key);
                if (toUpperCase) {
                    skey = skey.toUpperCase();
                }
                // Add the record to the resulting Map (indexed by the property value)}
                resultMap.put(skey, record);
            }
        }    
        return resultMap;
    }
    
    /**
     * Converts a List of any sObject in a map of <id, SObject>
     */
    public static Map<Id, SObject> listToMap(List<SObject> objects) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        for (SObject o : objects) {
            result.put(o.Id, o);
        }
        return result;
    } // listToMap


    /**
     * Converts a string with Yes/No or Y/N to boolean
     */
    public static Boolean englishToBoolean(String str) {
        Boolean result = false;
        if (String.IsNotBlank(str)) {
            result = (str.toUpperCase().substring(0, 1) == 'Y');
        }
        return result;
    } // englishToBoolean

    /**
     * Converts a boolean to Yes/No
     */
    public static String booleanToLabel(Boolean boolValue) {
        String result = Label.dict_no;
        if (boolValue) {
            result = Label.dict_yes;
        }
        return result;
    } // booleanToLabel

    /**
     * Returns blak is a string is null
     */
    public static String deNullify(String value) {
        if (value == null) {
            return '';
        } else {
            return value;            
        }
    }
    
} // class