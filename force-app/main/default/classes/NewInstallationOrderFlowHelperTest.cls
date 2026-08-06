@isTest public class NewInstallationOrderFlowHelperTest {

	@testSetup static void setup() {
 		Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    } // setup
    
    @isTest static void getInstallationOrders() {
        // Create test data
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);        
        String requestId = requests[0].Id;  
        List<String> ids = new List<String>();        
        ids.add(requestId);
        
        // Test 1 - No installation order should be returned
        List<InstallationOrder__c> result = NewInstallationOrderFlowHelper.getInstallationOrders(ids);
        integer size = 0;
        if (result != null) {
            size = result.size();
        }
        System.assertEquals(size, 0, 'No installation order should have been returned!!!');
        
        // Test2 - One I.O. should be returned
        DataFactoryInstallation.createInstallationOrders(requests);
        result = NewInstallationOrderFlowHelper.getInstallationOrders(ids);
        System.assertEquals(result.size(), 1, 'One installation order should have been returned!!!');

    } // getInstallationOrders

}