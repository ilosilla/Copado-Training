/**
* @author 	Ramón Prades
* @date 	August 2020
*
* @group 	Installations
* @group-content ../../ApexDocContent/Installations.htm
*
* @description Test class for FlashCardInsRequestController
*/

@isTest public class FlashCardInsRequestControllerTest {
    
    @testsetup public static void setup() {
        TestUtils.enableTriggers();
    } // setup
    
    @isTest public static void getRequest() {
        InstallationRequest__c req = DataFactoryInstallation.createInstallationRequests(1)[0];
        List<sObject> results = FlashCardInsRequestController.getRequest(req.Opportunity__c);
		System.assertEquals(results.size(), 2, 'The list of results should have 2 items (request and installer)');                        
        
        InstallationRequest__c resultIns = (InstallationRequest__c) results[0];        
        System.assertEquals(resultIns.Id, req.Id, 'Wrong id of returned opp');                
    } // getRequest

}