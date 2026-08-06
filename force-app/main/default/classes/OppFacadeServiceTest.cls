@isTest public  class OppFacadeServiceTest {

    @testSetup private static void testSetup() {
        DataFactoryOppFacade.createFacade();
    }

    @isTest private static void testDeleteFacade() {
        OppFacade__c facade = [select Id from OppFacade__c limit 1];
        Boolean result = OppFacadeService.deleteFacade(facade.Id);
        System.assertEquals(false, result, 'The Facade has attachements and should not have been deleted');
    }

    @isTest private static void testDeleteFacade2() {        
        OppFacade__c facade = [select Id from OppFacade__c limit 1];
        ContentDocumentLink[] docs = [select Id from ContentDocumentLink where LinkedEntityId = :facade.Id];
        delete docs;
        SystemSettings.CPNotificationsEnabled = true;
        Test.startTest();
            Boolean result = OppFacadeService.deleteFacade(facade.Id);
            Integer emails = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(true, result, 'The Facade has no attachements and should have been deleted');  
        System.assertNotEquals(0, emails, 'An email should have been sent');  
    }

} // class