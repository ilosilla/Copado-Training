@isTest
public class InstallationRequestsSelectorTest {
     
    @testSetup static void setup() {
        TestUtils.enableTriggers();
    } // setup
    
    @isTest static void test() {
		List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        
        InstallationRequest__c aux = new InstallationRequestsSelector().selectById(requests[0].Id);
        System.assert(aux != null, 'No se ha devuelto el registro buscado');
        List<InstallationRequest__c> auxList = new InstallationRequestsSelector().selectById(new Set<Id>{requests[0].Id});
        System.assert(auxList.size() > 0, 'No se ha devuelto el registro buscado');
    }
}