@isTest
public class DataFactoryInstallationTest {
    
    private static final Integer NUM_ACCOUNTS = 3;
        
    @testSetup static void setup() {
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }

    @isTest static void createInstallationRequests() {
		DataFactoryInstallation.createInstallationRequests(NUM_ACCOUNTS);
        List<InstallationRequest__c> requests = [select Id from InstallationRequest__c];               
        System.assertEquals(requests.size(), NUM_ACCOUNTS, 'The number of installation requests do not match the number requested');        
    } // createInstallationRequests
    
    @isTest static void createInstallationOrders() {
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(NUM_ACCOUNTS);
        DataFactoryInstallation.createInstallationOrders(requests);
        List<InstallationOrder__c> orders = [select Id from InstallationOrder__c];               
        System.assertEquals(requests.size(), orders.size(), 'The number of installation orders created does not match the requests');        
    } // createInstallationOrders    
        
} // class