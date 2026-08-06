@isTest
public class b2b_customLookupController_Test {
	static testMethod void testFetchLookupData() {
        // Insert some test data for the lookup object
		PorcelanosaAddress__c testAccounts = new PorcelanosaAddress__c();
        testAccounts.NBK_Address__CountryCode__s = 'US';
        testAccounts.NBK_isActive__c = true;
        testAccounts.NBK_isWarehouse__c = true;
        insert testAccounts;

        // Call the method to be tested
        List<sObject> result = b2b_customLookupController.fetchLookupData('US', 'PorcelanosaAddress__c');
    }
    
   	static testMethod void testFetchLookupDataEmpty() {
        // Call the method to be tested
        List<sObject> result = b2b_customLookupController.fetchLookupData('US', 'PorcelanosaAddress__c');
    }
}