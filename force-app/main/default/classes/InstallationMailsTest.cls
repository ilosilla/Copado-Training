@isTest
public class InstallationMailsTest {
    @testSetup static void setup() {
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        List<InstallationRequest__c> requests = DataFactoryInstallation.createInstallationRequests(5);
        List<InstallationOrder__c> orders = DataFactoryInstallation.createInstallationOrders(requests);
    }

    @isTest
    static void openInstallations() {
        Test.startTest();
        InstallationMails.openInstallations();
        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'Mail not sent. Mails sent: ' + invocations);
        Test.stopTest();
    }

    @isTest
    static void changeStateInsrMail() {
        List<InstallationRequest__c> listInsrNew = [SELECT Id, State__c, OwnerId, Name, LastModifiedById from InstallationRequest__c];
        List<InstallationRequest__c> listInsrOld = [SELECT Id, State__c, OwnerId, Name, LastModifiedById from InstallationRequest__c];
        List<User> usrList = [SELECT Id, ProfileId from User where Id <> : listInsrNew[0].OwnerId];
        User auxAdmin = null;
        for (User aux : usrList) {
            if (UserUtils.isAdministrator(aux) == true && aux.Id != listInsrNew[0].OwnerId) {
                auxAdmin = aux;
            }
        }

        listInsrNew[0].State__c = '3D Design';
        listInsrNew[0].OwnerId = auxAdmin.Id;
        
        Test.startTest();
        InstallationMails.changeStateInsrMail(listInsrOld,listInsrNew);
        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'Mail not sent. Mails sent: ' + invocations);
        Test.stopTest();
    }
}