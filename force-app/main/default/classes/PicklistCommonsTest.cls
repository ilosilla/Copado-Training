@isTest public with sharing class PicklistCommonsTest {

    @isTest private static void testA() {
        Map<String, String> v = PicklistCommons.getValues(Account.Industry);
        System.assertNotEquals(0, v.size(), 'Values should have been found');
        
        List<String> picked = new List<String>();
        picked.add('X_X_X_X_X_X');
        List<String> keys = new List<String>(v.keyset());        
        picked.add(keys[0].toLowerCase());
        List<String> result = PicklistCommons.validatePicklistValues(Account.Industry, picked);
        System.assertEquals(1, result.size(), 'Only one key was correct');
    }

    @isTest private static void testB() {
        Map<String, String> v = PicklistCommons.getValues(Account.Industry);
        System.assertNotEquals(0, v.size(), 'Values should have been found');    
        List<String> keys = new List<String>(v.keyset());        
        System.assertEquals(true, PicklistCommons.isPicklistValue(Account.Industry, keys[0]));
        System.assertEquals(false, PicklistCommons.isPicklistValue(Account.Industry, 'xsdsfds'));
    }


    @isTest private static void testC() {
        List<String> keys = PicklistCommons.getKeysList(Account.Industry);
        Assert.isTrue(keys.size() > 0, 'List of keys should not be empty');
    }


}