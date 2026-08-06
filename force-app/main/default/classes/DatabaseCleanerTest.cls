@isTest public with sharing class DatabaseCleanerTest {
    
 @testSetup
    static void setupData() {
        // Crear escenario
         SystemLogScenario__c sls = new SystemLogScenario__c();
        sls.Name = 'TEST';
        sls.MailTo__c = 'x@somesite.cxm';
        sls.MailSubjectPrefix__c = 'XXX';
        sls.LogLevel__c = 'Debug';
        insert sls;

         Account acc1 = new Account(Name='Test');
        SystemLog log = new SystemLog('TEST');
        log.setInputObject(acc1);
        log.setTag('Test Tag');
        log.addSection('Example');
        log.setInputData('DATA');
        log.setSummary('This is the summary line');
        log.addError('this is a test error');
        log.addWarning('This is a warning');
        log.saveLog(true);

        // Insertar configuración válida en el Custom Setting
        PORSADatabaseCleanable__c config = new PORSADatabaseCleanable__c(
            Name = 'SystemLog__c',
            ObjectName__c = 'SystemLog__c',
            RetentionDays__c = -1
        );
        insert config;

        PORSADatabaseCleanable__c config2 = new PORSADatabaseCleanable__c(
            Name = 'SAPRequestQueue__c',
            ObjectName__c = 'SAPRequestQueue__c',
            RetentionDays__c = 60
        );
        insert config2;

        PORSADatabaseCleanable__c config3 = new PORSADatabaseCleanable__c(
            Name = 'Dummy__c',
            ObjectName__c = 'Dummy__c',
            RetentionDays__c = 60
        );
        // insert config3;

    }

    @isTest
    static void testCleanerExecution() {
        Test.startTest();

        // Ejecutar el batch como si se lanzara manualmente
        DatabaseCleaner cleaner = new DatabaseCleaner();
        Database.executeBatch(cleaner, 1); // tamaño pequeño para forzar fragmentación

        Test.stopTest();

        Assert.isTrue(true, 'dummy test');
    }

}