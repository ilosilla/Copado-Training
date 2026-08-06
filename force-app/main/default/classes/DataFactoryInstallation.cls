/**
 * @author Ramón Prades
 * @date July 2020
 *
 * @group Opportunities
 * @group-content ../../ApexDocContent/Opportunities.htm
 *
 * @description Class to create test installation requests and test installation orders
 */
public class DataFactoryInstallation {

    /**
   	 * @description 		Creates installation requests
   	 * @param theNumber		Number of installation requests
   	 * @return				The list of installations created
     */        
    public static List<InstallationRequest__c> createInstallationRequests(Integer theNumber) {
        List<Account> accounts = DataFactoryAccount.createPersonAccounts(theNumber+1);
        Account installer = accounts[0];
        accounts.remove(0);
        List<Opportunity>opps = DataFactoryOpportunity.createRetailOpportunities(accounts, 1);        
        return DataFactoryInstallation.createInstallationRequests(opps, installer);                
    }    

    /**
   	 * @description 		Creates an installation request
   	 * @param opps			List of retail opportunitites	 
   	 * @param installer		Id of the installer
   	 * @return				The list of installations created
     */    
	public static List<InstallationRequest__c> createInstallationRequests(List<Opportunity> opps, Account installer) {
        List<InstallationRequest__c> requests = new List<InstallationRequest__c>();
        if(Test.isRunningTest()) {  
            Integer i = 0;
            for (Opportunity opp : opps) {                
                InstallationRequest__c request = new InstallationRequest__c(
													Name= 'Test Retail Opportunity #' + i, 
                                            		bathrooms__c = 1, 
                                                    Description__c = 'Description of the test intallation request',
                                                   	InstallerAccount__c = installer.Id,
                                                    Opportunity__c = opp.Id);
				requests.add(request);
                i++;
            } // for 
            insert requests;
        } // if test
        return requests;
    } // createInstallationRequests
    
    /**
   	 * @description 		Creates an installation order for an installation request
   	 * @param requests		List of installation requests
   	 * @param installer		Id of the installer
   	 * @return				The list of installations created
     */    
	public static List<InstallationOrder__c> createInstallationOrders(List<InstallationRequest__c> requests) {
        List<InstallationOrder__c> orders = new List<InstallationOrder__c>();
        if(Test.isRunningTest()) {  
            Integer i = 0;
            for (InstallationRequest__c request : requests) {                
                InstallationOrder__c order = new InstallationOrder__c(
													Name= 'Installation order #' + i, 
                									Installation_Request__c = request.Id);
				orders.add(order);
                i++;
            } // for 
            insert orders;
        } // if test 
        return orders;
    } // createInstallationOrders
        
    
} // class