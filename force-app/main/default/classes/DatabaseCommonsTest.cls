/**
* @author 		Ramón Prades
* @date 		March 2023
* @group 		Commons
* @description  Test class for databaseCommons
*/
@isTest public class DatabaseCommonsTest {

    @isTest
    static void testGetObjectFields() {

        // Call the getFieldList method for the Account object
        String fieldList = DatabaseCommons.getFieldList('Account');

        // Verify that the field list contains expected fields
        Assert.isTrue(fieldList.containsIgnoreCase('Id'));
        Assert.isTrue(fieldList.containsIgnoreCase('Name'));
    }

    @isTest
    static void testGetRealFieldNames() {

        // Call the getRealFieldNames method for the Account object
        String[] realFieldNames = DatabaseCommons.getRealFieldNames('Account');

        // Verify that the real field names contain expected fields
        Assert.isTrue(realFieldNames.contains('Id'));
        Assert.isTrue(realFieldNames.contains('Name'));
    }

    
}