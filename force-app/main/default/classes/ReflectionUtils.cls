/**
* @author 		Ramón Prades
* @date 		May 2021
* @group 		Utils
* @description 	Reflection like methods to retrieve info about metadata
*/
public with sharing class ReflectionUtils {

    /**
     * Gets the labels of an object's fields 
     */
    public static Map<String, String> getFieldNames(String objectName) {
        Map<String, String> fieldsMap = new Map<String, String>();
        DescribeSObjectResult objDef = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();     
        Set<String> fieldSet = fields.keySet();
        for(String s:fieldSet)
        {
            SObjectField fieldToken = fields.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            System.debug(selectedField.getName());
            fieldsMap.put(selectedField.getName(), selectedField.getLabel() );
        }    
        return fieldsMap;
    } // getFieldNames

    /**
     * Gets the list of values of a picklist field (all active entries regardless of the record type)
     * Example: getPicklistValues(Account.Industry)
     */
    public static List<Schema.PicklistEntry> getPicklistValues(Schema.sObjectField field) {
        List<Schema.PicklistEntry> entries = field.getDescribe().getPickListValues();
        // Only return active picklist values
        List<Schema.PicklistEntry> activeEntries = new List<Schema.PicklistEntry>();
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                activeEntries.add(entry);
            }
        }
        return activeEntries;
    } // getPicklistValues

    /**
     * Gets the map (value, label) of a picklist field (all active fields regardless of the record type)
     * Example: getPicklistValues(Account.Industry)
     */
    public static Map<String, String> getPicklistValuesMap(Schema.sObjectField field) {
        Map<String, String> result = new Map<String,String>();
        List<Schema.PicklistEntry> entries = ReflectionUtils.getPicklistValues(field);
        for (Schema.PicklistEntry entry : entries) {
            result.put(entry.getValue(), entry.getLabel());
        }
        return result;
    } // getPicklistValuesMap


} // class