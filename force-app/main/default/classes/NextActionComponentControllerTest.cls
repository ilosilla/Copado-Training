@IsTest
public class NextActionComponentControllerTest {

    @TestSetup
    static void setup(){
        TestUtils.enableTriggers();
        Insert Account_TestDataFactory.createBusinessAccount();

        NextActionText__c actionText = new NextActionText__c(Object__c = 'Opportunity', Status__c = 'Especificación', Label__c = 'dict_edit');
        NextActionText__c actionText2 = new NextActionText__c(Object__c = 'Opportunity', Status__c = 'New', Label__c = 'dict_edit');
        insert actionText;
        insert actionText2;
    }

    @isTest
    static void test() {
        Account acc = [SELECT Id, Last_Activity_Date__c FROM Account LIMIT 1];

        Opportunity newOpp = Opportunity_TestDataFactory.createTrade(acc);
        Insert newOpp;
        
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(1);
        InstallationRequest__c installationReq = requests[0];
        
        Map<String, String> auxOpp = NextActionComponentController.getLabel(newOpp.Id);
        Map<String, String> auxAcc = NextActionComponentController.getLabel(acc.Id);
        Map<String, String> auxInstallation = NextActionComponentController.getLabel(installationReq.Id);
        System.assert(auxOpp.get('labelAPI') == 'dict_edit', 'No ha devuelto el label correcto');
        System.assert(auxAcc.get('labelAPI') == null, 'No debería haber devuelto un Label');
        System.assert(auxInstallation.get('labelAPI') == null, 'No debería haber devuelto un Label');
    }
    
}