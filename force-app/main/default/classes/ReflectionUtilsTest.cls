@isTest public with sharing class ReflectionUtilsTest {

    @isTest public static void getFIeldNames() {
        Map<String, String> fields = ReflectionUtils.getFieldNames('Account');
        System.assertNotEquals(0, fields.size(), 'Unexpected result');
    }

    @isTest public static void getPicklistValues() {
        List<Schema.PicklistEntry> values = ReflectionUtils.getPicklistValues(Account.Industry);
        System.assertNotEquals(0, values.size(), 'The field should have values!');
    }
        
    @isTest public static void getPicklistValuesMap() {
        Map<String, String> m = ReflectionUtils.getPicklistValuesMap(Account.Industry);
        System.assertNotEquals(0, m.size(), 'The field should have values!');
    }

}