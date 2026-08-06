@isTest
public class InstallationRequestTriggerHandlerTest {
     
    @testSetup static void setup() {
        TestUtils.enableTriggers();
    } // setup
    
    @isTest static void beforeUpdate() {
        Id me = UserInfo.getUserId();
        
		List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        InstallationRequest__c request1 = requests[0];
        
        // Check acceptedBy fields
        request1.State__c = InstallationUtil.acceptedState;
        update request1;        
        InstallationRequest__c request2 = [select Id, AcceptedBy__c from InstallationRequest__c where Id = :request1.Id][0];        
        System.AssertEquals(request2.AcceptedBy__c, me, 'User accepting the request not set properly');
        
        // Check transition date set
        request1.State__c = InstallationUtil.rejectedState;
        request1.ReasonRejected__c = 'test';
        update request1;
        request2 = [select Id, LastTransition__c from InstallationRequest__c where Id = :request1.Id][0];                
		System.assertEquals(Date.today(), request2.LastTransition__c, 'Unexpected transition date');  
        
        // check ReasonRejected removed when transition back to another state
        request1.State__c = InstallationUtil.acceptedState;
        update request1;                 
        request2 = [select Id, ReasonRejected__c from InstallationRequest__c where Id = :request1.Id][0];                
        System.AssertEquals(null, request2.ReasonRejected__c, 'ReasonRejected should have been deleted');        
        
    } // beforeUpdate
    
    @isTest static void beforeInsert() {
        Id me = UserInfo.getUserId();
        
		List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        InstallationRequest__c request1 = requests[0];
        InstallationRequest__c request2 = request1.clone();        
        request2.State__c = InstallationUtil.acceptedState;
        insert request2;        
        InstallationRequest__c request3 = [select Id, AcceptedBy__c from InstallationRequest__c where Id = :request2.Id][0];        
        System.AssertEquals(request3.AcceptedBy__c, me, 'User accepting the request not set properly');
    } // beforeInsert
    @isTest static void afterInsert() {
        Id me = UserInfo.getUserId();

        Test.startTest();
        List<Account> accounts = DataFactoryAccount.createPersonAccounts(2);
        Account installer = accounts[0];
        accounts.remove(0);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accounts, 1);        

        Account acc = new AccountsSelector().selectById(accounts[0].Id);
        acc.Last_Activity_Date__c = System.now().addDays(-8);
        update acc; 
        acc = new AccountsSelector().selectById(accounts[0].Id);
        
        System.assert(acc.Last_Activity_Date__c.date() != System.now().date(), 'La fecha de Activity no es anterior');
        
        DataFactoryInstallation.createInstallationRequests(opps, installer);
        Test.stopTest();
        
        acc = new AccountsSelector().selectById(acc.Id);
        System.assert(acc.Last_Activity_Date__c.date() == System.now().date(), 'La fecha de Activity no se ha actualizado');
    } // afterInsert
    

    @isTest static void beforeDelete() {
        
        Boolean error = false;
        Boolean error2 = false;
        
        List<InstallationRequest__c> base = DataFactoryInstallation.createInstallationRequests(6);
        List<InstallationRequest__c> requests1 = new List<InstallationRequest__c>();
        List<InstallationRequest__c> requests2 = new List<InstallationRequest__c>();
        
        for (Integer i = 0; i < base.size(); i++) {
            if (i<3) {
                requests1.add(base.get(i));
            } else {
                requests2.add(base.get(i));
            }
        }                
        
        List<InstallationOrder__c> orders = DataFactoryInstallation.createInstallationOrders(requests1);
        
        try {
            Delete 	requests1;
        } catch(Exception ee) {
            error = true;
        }
        
        try {
            Delete 	requests2;
        } catch(Exception ee) {
            error2 = true;
        }
    	
        System.assertEquals(error, true, 'Request deleted (but has installation orders!)');
		System.assertEquals(error2, false, 'Request not deleted (and it should have been deleted!)');
        
    } // beforeDelete    
    

}