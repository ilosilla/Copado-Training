@isTest public class InstallationOrderSummaryControllerTest {
	@testSetup static void setup() {
		TestUtils.enableTriggers();
    } // setup
    
    @isTest static void	getOrderFromRequest() {
 		// Create test data
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        String requestId = requests[0].Id;  
        
        InstallationOrder__c order = InstallationOrderSummaryController.getOrderFromRequest(requestId);
        System.assertEquals(order, null, 'No installation order should have been returned!!!');        

        DataFactoryInstallation.createInstallationOrders(requests);                
        order = InstallationOrderSummaryController.getOrderFromRequest(requestId);
        System.assertNotEquals(order, null, 'No installation order has been returned!!!');
                
    } // getOrderFromRequest
        
} // InstallationOrderSummaryControllerTest