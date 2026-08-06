@isTest
private class CustomObjectUsageBatchTest {

    @isTest
    static void testBatchExecution_alpha() {
        createSampleRecords();

        Test.startTest();
        CustomObjectUsageBatch batch = new CustomObjectUsageBatch('test@example.com', 'alpha');
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

    @isTest
    static void testBatchExecution_low30() {
        createSampleRecords();

        Test.startTest();
        CustomObjectUsageBatch batch = new CustomObjectUsageBatch('test@example.com', 'low30');
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

    @isTest
    static void testBatchExecution_noRecent90() {
        createSampleRecords();

        Test.startTest();
        CustomObjectUsageBatch batch = new CustomObjectUsageBatch('test@example.com', 'noRecent90');
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

    private static void createSampleRecords() {
        // Usa un objeto custom real de tu org. Esto es un ejemplo.
        // Si no existe TestObject__c, reemplaza con un objeto __c válido.
        if (Schema.getGlobalDescribe().containsKey('porcelanosaaddress__c')) {
            porcelanosaaddress__c obj = new porcelanosaaddress__c(Name = 'Prueba');
            insert obj;
        }
    }
}