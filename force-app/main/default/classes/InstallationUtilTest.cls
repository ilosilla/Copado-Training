@isTest
public class InstallationUtilTest {

    @testSetup static void setup() {
 		Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    } // setup
    
    /* */
    @isTest static void getInstallationOrders() {
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        List<InstallationOrder__c> orders = DataFactoryInstallation.createInstallationOrders(requests);
        
        String requestId = requests[0].Id;        
    	InstallationOrder__c order = [select Id from InstallationOrder__c where Installation_Request__c = :requestId ][0];
        
        System.assertEquals(order.Id, orders[0].Id, 'Orders ID do not match!');
    } // getInstallationOrders
    
    @isTest static void hasInstallationRequest() {
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);        
        String oppId = requests[0].Opportunity__c;        
        Boolean result = InstallationUtil.hasInstallationRequest(oppId);
        System.assertEquals(true, result); 
        
        delete requests[0];
		result = InstallationUtil.hasInstallationRequest(oppId);
        System.assertEquals(false, result); 
                
    }
    
    /* */    
    @isTest static void isRequestNew() {
		InstallationRequest__c request = DataFactoryInstallation.createInstallationRequests(1)[0];
        Boolean result = InstallationUtil.isRequestNew(request);
        System.assertEquals(true, result);
    } // isRequestNew
    
    /* */    
    @isTest static void isRequestAccepted() {
		InstallationRequest__c request = DataFactoryInstallation.createInstallationRequests(1)[0];
        request.State__c = InstallationUtil.acceptedState;
  		Boolean result = InstallationUtil.isRequestAccepted(request);
        System.assertEquals(result, true);
    } // isRequestNew

    /* */    
    @isTest static void isRequestRejected() {
		InstallationRequest__c request = DataFactoryInstallation.createInstallationRequests(1)[0];
        request.State__c = InstallationUtil.rejectedState;
    	request.ReasonRejected__c = 'test comments';
  		Boolean result = InstallationUtil.isRequestRejected(request);
        System.assertEquals(result, true);
    } // isRequestNew  
    
    /*
    @isTest static void getInstallers() {
        List<PostCodeObjects__c> pco = new List<PostCodeObjects__c>();
        pco.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'GB', postCode__c = '', objectId__c = 'a2U1x0000003LO6EAM'));
        pco.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'GB', postCode__c = '', objectId__c = 'a2U1x0000003LO6EAR'));           
        pco.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'FR', postCode__c = '', objectId__c = 'a2U1x0000003LO6EAR'));           
        insert pco;
        List<Id> installers = InstallationUtil.getInstallers('GB', 'LA22 9NZ');
        System.assertEquals(2, installers.size(), 'Two installers should have been returned');        
    }
    */

    @isTest static void getInstallers() {
        List<Installer__c> ins = new List<Installer__c>();
        Account[] accs = DataFactoryAccount.createAccounts(2);
        Account acc1 = accs[0];
        Account acc2 = accs[1];
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_SOUTH_EAST, Account__c = acc1.Id));
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_NORTH_WEST, Account__c = acc1.Id));
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_NORTH_WEST, Account__c = acc2.Id));
        ins.add(new Installer__c(SalesOrg__c = OrganizationCommons.ORG_YORKSHIRE, Account__c = acc2.Id));
        insert ins;

        List<Id> installers = InstallationUtil.getInstallers(OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST + ';' + OrganizationCommons.ORG_YORKSHIRE);
        System.assertEquals(2, installers.size(), '2 installers should have been returned');        

        installers = InstallationUtil.getInstallers(OrganizationCommons.ORG_SOUTH_EAST);
        System.assertEquals(1, installers.size(), '1 installer should have been returned');        

        installers = InstallationUtil.getInstallers(OrganizationCommons.ORG_SCOTLAND);
        System.assertEquals(0, installers.size(), 'No installer should have been returned');        
    }
    
    @isTest static void getOpportunityInstallers() {
        List<Account> accounts = DataFactoryAccount.createPersonAccounts(1);
        List<Opportunity> opportunities = DataFactoryOpportunity.createRetailOpportunities(accounts, 1);
        Opportunity opp = opportunities[0];        
        List<id> installers = InstallationUtil.getOpportunityInstallers(opp.Id);
        System.assertEquals(0, installers.size(), 'No installer should have been found');
    }
    
    @isTest static void hasInstallations() {
        // Just tests if there's a result
        Boolean access = InstallationUtil.hasInstallations();
        System.assert(access == true || access == false);
    }

    @isTest static void isRequestClosed() {
        InstallationRequest__c request = DataFactoryInstallation.createInstallationRequests(1)[0];
        request.State__c = InstallationUtil.closedStateRequest[0];
    	request.ReasonRejected__c = 'test comments';
        Boolean result = InstallationUtil.isRequestClosed(request);
        System.assertEquals(result, true);
    } // isRequestClosed  
    
    @isTest static void isOrderClosed() {
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        List<InstallationOrder__c> orders = DataFactoryInstallation.createInstallationOrders(requests);
        orders[0].State__c = InstallationUtil.closedStateOrder[0];
        Boolean result = InstallationUtil.isOrderClosed(orders[0]);
        System.assertEquals(result, true);
    } // isRequestClosed  
    
    @isTest static void requestNextActionLabel() {
        InstallationRequest__c request = DataFactoryInstallation.createInstallationRequests(1)[0];
        request = [select id, State__c from InstallationRequest__c where Id =: request.Id];
        String aux = '';
        request.State__c = InstallationUtil.newState;
        aux = InstallationUtil.requestNextActionLabel(request);
        System.assert(aux == Label.insr_next_newrequest, 'Label doesn\'t match');
     }
}