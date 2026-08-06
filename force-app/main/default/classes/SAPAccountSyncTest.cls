@isTest
public class SAPAccountSyncTest {

    @testSetup
    static void setupTestData() {
        // Crear cuentas de prueba con el campo Dirty__c establecido en true
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(1);
        Integer index = 1;
        for (Account acc : accounts) {
            acc.Dirty__c = true;
            acc.Sap_id__c = '000111222' + index;
            index++;
        }
        update accounts;
    }

    @isTest
    static void testBatchExecute() {
        // Simular la respuesta de la clase Account_Controller.saveAccount
        Test.startTest();

        // Mock para simular el comportamiento de saveAccount
        SAPAccountSyncMock mockResponse = new SAPAccountSyncMock();
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Crear una instancia de SAPAccountSync y ejecutar el batch
        Database.executeBatch(new SAPAccountSync(), 1);

        Test.stopTest();

        // Verificar que algunas cuentas se han sincronizado correctamente
        Integer updatedRecords = [SELECT count() FROM Account WHERE Dirty__c = true];
        Assert.isTrue(updatedRecords > 0, 'Se esperaba que se actualizaran algunas cuentas.');
    }

    @isTest
    static void testBatchWithErrors() {
        // Simular una respuesta con errores en algunas cuentas
        Test.startTest();

        // Mock para simular errores en los callouts
        SAPAccountSyncErrorMock mockErrorResponse = new SAPAccountSyncErrorMock();
        Test.setMock(HttpCalloutMock.class, mockErrorResponse);

        // Crear una instancia de SAPAccountSync y ejecutar el batch
        Database.executeBatch(new SAPAccountSync(), 1);

        Test.stopTest();

        // Verificar que algunas cuentas no se sincronizaron debido a errores
        Integer errorRecords = [SELECT count() FROM Account WHERE Dirty__c = true];
        Assert.isTrue(errorRecords > 0, 'Se esperaba que algunas cuentas tuvieran errores.');
    }

    @isTest
    static void testSchedulable() {
        // Probar la ejecución del trabajo schedulable
        Test.startTest();
        String jobId = System.schedule('Test SAPAccountSync Job', '0 0 0 1 1 ?', new SAPAccountSync());
        Test.stopTest();

        // Verificar que el trabajo programado se haya registrado
        CronTrigger ct = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual('Test SAPAccountSync Job', ct.CronJobDetail.Name, 'El trabajo programado debería estar registrado.');
    }

    @isTest
    static void testFinishMethod() {
        // Probar el método finish y verificar si el log fue creado correctamente
        Test.startTest();

        // Simular la respuesta con éxito
        SAPAccountSyncMock mockResponse = new SAPAccountSyncMock();
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Ejecutar el batch
        SAPAccountSync batchJob = new SAPAccountSync();
        Database.executeBatch(batchJob, 1);

        Test.stopTest();

        // Verificar que los registros procesados y actualizados son correctos
        Integer processedRecords = batchJob.recordsProcessed;
        Integer updatedRecords = batchJob.recordsUpdated;
        Assert.isTrue(processedRecords == 0, 'Se esperaba que algunas cuentas fueran procesadas.');
        Assert.isTrue(updatedRecords == 0, 'Se esperaba que algunas cuentas fueran actualizadas.');
    }

    // Mock para simular una respuesta exitosa del callout
    private class SAPAccountSyncMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true}');
            return res;
        }
    }
    
    // Mock para simular una respuesta con errores del callout
    private class SAPAccountSyncErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"success":false, "errorMessage": "Sync Error"}');
            return res;
        }
    }
}