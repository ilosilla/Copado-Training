@isTest public class DataFactoryOppFacadeTest {

    @testSetup private static void testSetup() {
        DataFactoryOppFacade.createFacade();
    }

    @isTest private static void testCreate() {
        List<OppFacade__c> fs = [select Id from OppFacade__c];
        System.assertNotEquals(0, fs.size(), 'There should have been at least a facade');
    }
}