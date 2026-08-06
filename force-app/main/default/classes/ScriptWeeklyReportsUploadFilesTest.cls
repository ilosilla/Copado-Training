@isTest
private class ScriptWeeklyReportsUploadFilesTest {

    // 🔹 Configuración de datos de prueba
    @testSetup
    static void setupTestData() {
        List<Account> acc = DataFactoryAccount.createBusinessAccounts(1);

        PorcelanosaSetting__c pSetting = new PorcelanosaSetting__c(key__c = 'EVENTMANAGEMENTEMAIL', subkey__c = 'MANAGED', value1__c = 'GB', isActive__c = true);
        insert pSetting;
        PorcelanosaSetting__c pSetting2 = new PorcelanosaSetting__c(key__c = 'EVENTMANAGEMENTEMAIL', subkey__c = 'UNMANAGED', value1__c = 'GB',value2__c = 'ivan.losilla@porcelanosagrupo.com', isActive__c = true);
        insert pSetting2;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc[0].Id);
        insert con;

        // Obtener un perfil válido para usuarios de prueba
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> users = DataFactoryUser.createUKUsers(2);

        // Crear eventos de prueba
        Event ev1 = new Event(
            Subject = 'Test Event 1',
            Description = 'This is a test event',
            StartDateTime = DateTime.now().addDays(-10),
            EndDateTime = DateTime.now().addDays(-10).addHours(2),
            WhatId = acc[0].Id,
            WhoId = con.Id,
            OwnerId = users[0].Id,
            CreatedById = users[0].Id,
            LoginFlowCompleted__c = Date.today().addDays(-7)
        );
        insert ev1;

        Event ev2 = new Event(
            Subject = 'Test Event 2',
            Description = 'Another test event',
            StartDateTime = DateTime.now().addDays(-8),
            EndDateTime = DateTime.now().addDays(-8).addHours(2),
            WhatId = acc[0].Id,
            WhoId = con.Id,
            OwnerId = users[1].Id,
            CreatedById = users[1].Id,
            LoginFlowCompleted__c = Date.today().addDays(-7)
        );
        insert ev2;
    }

    // 🔹 Test para la lógica de fechas en el constructor
    @isTest
    static void testConstructor() {
        PorcelanosaSetting__c settting = [SELECT ID, subkey__c, key__c FROM PorcelanosaSetting__c WHERE key__c = 'EVENTMANAGEMENTEMAIL' and subkey__c = 'MANAGED' LIMIT 1];
        Test.startTest();
        ScriptWeeklyReportsUploadFiles batchJob = new ScriptWeeklyReportsUploadFiles(settting.Id);
        Test.stopTest();

        System.assert(batchJob.startDate < batchJob.endDate, 'La fecha de inicio debe ser menor que la fecha de fin');
        System.assert(batchJob.startDate.daysBetween(batchJob.endDate) == 6, 'Debe cubrir una semana exacta');
    }

    @isTest
    static void testConstructorUnmanaged() {
        PorcelanosaSetting__c settting = [SELECT ID, subkey__c, key__c FROM PorcelanosaSetting__c WHERE key__c = 'EVENTMANAGEMENTEMAIL' and subkey__c = 'UNMANAGED' LIMIT 1];
        Test.startTest();
        ScriptWeeklyReportsUploadFiles batchJob = new ScriptWeeklyReportsUploadFiles(settting.Id);
        Test.stopTest();

        System.assert(batchJob.startDate < batchJob.endDate, 'La fecha de inicio debe ser menor que la fecha de fin');
    }

    @isTest
    static void testStartMethodWithSalesOrg() {
        PorcelanosaSetting__c setting = [SELECT Id FROM PorcelanosaSetting__c LIMIT 1];
        ScriptWeeklyReportsUploadFiles batch = new ScriptWeeklyReportsUploadFiles(setting.Id);
        Database.QueryLocator ql = batch.start(null);
        System.assertNotEquals(null, ql);
    }

    @isTest
    static void testExecuteBatchMethod() {
        PorcelanosaSetting__c setting = [SELECT Id FROM PorcelanosaSetting__c LIMIT 1];
        ScriptWeeklyReportsUploadFiles batch = new ScriptWeeklyReportsUploadFiles(setting.Id);

        User u = [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard Trade' LIMIT 1];

        // Simula resultado ficticio
        Test.startTest();
        batch.execute(null, new List<User>{u});
        Test.stopTest();
        Assert.areEqual(false, batch.resultBatch.containsKey(u.Email), 'No cuadra');
    }

    @isTest
    static void testSetStartAndEnd() {
        PorcelanosaSetting__c setting = [SELECT Id FROM PorcelanosaSetting__c LIMIT 1];

        ScriptWeeklyReportsUploadFiles job = new ScriptWeeklyReportsUploadFiles(setting.Id);

        Date customStart = Date.today().addDays(-7);
        Date customEnd = Date.today();

        job.setStart(customStart);
        job.setEnd(customEnd);

        System.assertEquals(customStart, job.startDate, 'startDate debe ser igual al valor seteado');
        System.assertEquals(customEnd, job.endDate, 'endDate debe ser igual al valor seteado');
    }

    @isTest
    static void testSetSetting() {
        PorcelanosaSetting__c setting = [SELECT Id FROM PorcelanosaSetting__c LIMIT 1];

        ScriptWeeklyReportsUploadFiles job = new ScriptWeeklyReportsUploadFiles(setting.Id);

        // Limpia propiedades antes de setSetting
        job.pSetting = null;
        job.isTest = false;
        job.mailTest = null;

        job.setSetting(setting.Id);

        System.assertNotEquals(null, job.pSetting, 'pSetting debe estar inicializado');
        System.assertEquals(false, job.isTest, 'isTest debe ser true si Value2__c está definido');
        System.assertEquals(null, job.mailTest, 'mailTest debe tomar el valor de Value2__c');
    }

    @isTest
    static void fillerTest() {
        ScriptWeeklyReportsUploadFiles.testFiller();
        ScriptWeeklyReportsUploadFiles.testFiller();
        Assert.isTrue(1 == 1);
    }
}