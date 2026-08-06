/**
* @author 		Ramón Prades
* @date 		March 2023
* @group 		Commons
* @description  Utility methods to handle database operations
*/
public class DatabaseCommons {

    /**
     * Returns a comma-separated list of all fields of a specified Salesforce object (/in lower case).
     */
    public static String getFieldList(String objectName) {
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String fieldsList = '';
        String sep = '';
        for (String fieldValue : objectFields.keySet()) {
            fieldsList += sep + fieldValue;
            sep = ', ';
        }
        return fieldsList;
    } // getFieldList

    public static String[] getRealFieldNames(String objectName) {
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields
            .getMap();
        List<String> realFieldNames = new List<String>();
        for (String fieldValue : fieldMap.keySet()) {
            realFieldNames.add(fieldMap.get(fieldValue).getDescribe().getName());
        }
        return realFieldNames;
    } // getRealFieldNames

} // class