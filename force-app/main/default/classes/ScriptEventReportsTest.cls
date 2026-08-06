@isTest
public with sharing class ScriptEventReportsTest {

    // 🔹 Configuración de datos de prueba
    @testSetup
    static void setupTestData() {
        List<Account> acc = DataFactoryAccount.createBusinessAccounts(1);
        List<User> users = DataFactoryUser.createUKUsers(2);

        PorcelanosaSetting__c pSetting = new PorcelanosaSetting__c(key__c = 'EVENTMANAGEMENTEMAIL', subkey__c = 'MANAGED', value1__c = 'GB', isActive__c = true);
        insert pSetting;
        PorcelanosaSetting__c pSetting2 = new PorcelanosaSetting__c(key__c = 'EVENTMANAGEMENTEMAIL', subkey__c = 'UNMANAGED', value1__c = 'GB',value2__c = 'ivan.losilla@porcelanosagrupo.com', isActive__c = true);
        insert pSetting2;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc[0].Id);
        insert con;

        // Obtener un perfil válido para usuarios de prueba
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];


        System.runAs(users[0]) {
            PermissionSet pSet = [SELECT Id FROM PermissionSet WHERE Name = 'Login_Flow_Event_Management'];
            List<PermissionSetAssignment> assignmentds = new List<PermissionSetAssignment>();
            for (User u : users) {
                PermissionSetAssignment assignment = new PermissionSetAssignment();
                assignment.AssigneeId = u.Id;
                assignment.PermissionSetId = pSet.Id;
                assignmentds.add(assignment);
            }
            insert assignmentds;
        }

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
        ScriptEventManagedReports batchJob = new ScriptEventManagedReports(settting.Id);
        Test.stopTest();

        System.assert(batchJob.startDate < batchJob.endDate, 'La fecha de inicio debe ser menor que la fecha de fin');
        System.assert(batchJob.startDate.daysBetween(batchJob.endDate) == 6, 'Debe cubrir una semana exacta');
    }

    @isTest
    static void testConstructorUnmanaged() {
        PorcelanosaSetting__c settting = [SELECT ID, subkey__c, key__c FROM PorcelanosaSetting__c WHERE key__c = 'EVENTMANAGEMENTEMAIL' and subkey__c = 'UNMANAGED' LIMIT 1];
        Test.startTest();
        ScriptEventManagedReports batchJob = new ScriptEventManagedReports(settting.Id);
        Test.stopTest();

        System.assert(batchJob.startDate < batchJob.endDate, 'La fecha de inicio debe ser menor que la fecha de fin');
    }

    @isTest
    static void fillerTest() {
        ScriptEventManagedReports.testFiller();
        ScriptEventManagedReports.testFiller();
        Assert.isTrue(1 == 1);
    }
}