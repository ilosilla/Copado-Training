@isTest
public class ScriptCreateWeeklyReportEventTest {

    @isTest
    static void testSchedulableExecute() {
        ScriptCreateWeeklyReportEvent batch = new ScriptCreateWeeklyReportEvent();
        Test.startTest();
        String jobId = System.schedule('Test Weekly Report Scheduler', '0 0 12 * * ?',batch);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'El job ID no debe ser null');
    }

    @isTest
    static void testFullBatchExecution() {
        ScriptCreateWeeklyReportEvent batch = new ScriptCreateWeeklyReportEvent();

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Event> createdEvents = [SELECT Id, OwnerId FROM Event];
        System.assert(createdEvents.size() > 0, 'Deben haberse creado eventos en la ejecución completa');
    }
}