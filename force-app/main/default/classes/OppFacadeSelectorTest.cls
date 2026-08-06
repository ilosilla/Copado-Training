@isTest public class OppFacadeSelectorTest {
    @testSetup private static void testSetup() {
        DataFactoryOppFacade.createFacade();
    }

    @isTest private static void testSelectById() {
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        OppFacade__c result = OppFacadeSelector.selectById(f.Id);
        System.assertEquals(f.Id, result.Id, 'Facade not read');
    }

    @isTest private static void testSelectByIdWithLabels() {
        OppFacade__c f = [select Id from OppFacade__c limit 1];
        OppFacade__c result = OppFacadeSelector.selectByIdWithLabels(f.Id);
        System.assertEquals(f.Id, result.Id, 'Facade not read');
    }

}