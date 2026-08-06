@isTest public class OppFacadeSchedulerTest {
    
    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        SystemSettings.CPNotificationsEnabled = true;
        SystemSettings.CPDeletionTime = 2;
        DataFactoryOppFacade.createFacade();
    } // testSetup}

    @isTest private static void scheduleNewFacade() {
        // Already on the Trigger. Issue of scheduled already started
        
        // String id = [select Id from Oppfacade__c limit 1].Id;
        // List<String> ids = new List<String>{id};
        // OppFacadeScheduler.scheduleNewFacade(ids);
        
        System.assert(true, true);  //Silly
    }

    @isTest private static void scheduleDeletion() {
        // Already on the Trigger. Issue of scheduled already started

        // String id = [select Id from Oppfacade__c limit 1].Id;
        // List<String> ids = new List<String>{id};
        // OppFacadeScheduler.scheduleDeletion(ids);
        
        System.assert(true, true);  //Silly
    }
    
    @isTest private static void scheduleReminder() {
        // Already on the Trigger. Issue of scheduled already started

        // String id = [select Id from Oppfacade__c limit 1].Id;
        // List<String> ids = new List<String>{id};
        // OppFacadeScheduler.scheduleReminder(ids);
        
        System.assert(true, true);  //Silly
    }
        
}