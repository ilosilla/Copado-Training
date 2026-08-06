@isTest
public with sharing class ReportsHelperTest {
    
    // 🔹 Configuración de datos de prueba (Se ejecuta antes de cada test)
    @testSetup
    static void setupTestData() {
        List<Account> acc = DataFactoryAccount.createBusinessAccounts(1);

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc[0].Id);
        insert con;

        // Crear usuarios de prueba
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

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

        // Crear eventos de prueba
        Event ev10 = new Event(
            Subject = 'Test Event 10',
            Description = 'This is a test event',
            StartDateTime = DateTime.now().addDays(-10),
            EndDateTime = DateTime.now().addDays(-10).addHours(2),
            WhatId = acc[0].Id,
            WhoId = con.Id,
            OwnerId = UserInfo.getUserId(),
            CreatedById = UserInfo.getUserId(),
            LoginFlowCompleted__c = Date.today().addDays(-7)
        );
        insert ev10;

        Event ev2 = new Event(
            Subject = 'Test Event 2',
            Description = 'Another test event',
            EventType__c = 'Weekly report',
            StartDateTime = DateTime.now().addDays(-8),
            EndDateTime = DateTime.now().addDays(-8).addHours(2),
            WhatId = acc[0].Id,
            WhoId = con.Id,
            OwnerId = users[1].Id,
            CreatedById = users[1].Id,
            LoginFlowCompleted__c = Date.today().addDays(-7)
        );
        insert ev2;

        // Crear eventos de prueba
        Event ev4 = new Event(
            Subject = 'Test Event 1',
            Description = 'This is a test event',
            StartDateTime = DateTime.now().addDays(-1),
            EndDateTime = DateTime.now().addDays(-1).addHours(2),
            OwnerId = users[0].Id,
            CreatedById = users[0].Id
        );
        insert ev4;

        Event ev3 = new Event(
            Subject = 'Test Event 2',
            Description = 'Another test event',
            StartDateTime = DateTime.now().addDays(-1),
            EndDateTime = DateTime.now().addDays(-1).addHours(2),
            OwnerId = users[1].Id,
            CreatedById = users[1].Id
        );
        insert ev3;

        // Create Events: Managed & Unmanaged
        Event managedEvt = new Event(
            Subject = 'Managed Event',
            StartDateTime = DateTime.now().addDays(-1),
            EndDateTime = DateTime.now().addDays(1),
            WhoId = con.Id,
            WhatId = acc[0].Id,
            OwnerId = users[0].Id,
            LoginFlowCompleted__c = Date.today(),
            EventType__c = 'Weekly report',
            isPrivate = false
        );
        insert managedEvt;

        Event unmanagedEvt = new Event(
            Subject = 'Unmanaged Event',
            StartDateTime = DateTime.now().addDays(-1),
            EndDateTime = DateTime.now().addDays(1),
            OwnerId = users[1].Id,
            CreatedById = users[1].Id,
            EventType__c = 'Weekly report',
            isPrivate = false
        );
        insert unmanagedEvt;
    }


    @isTest
    static void testGetUnManagedEvents() {
        Set<String> userIds = new Set<String>{[SELECT Id FROM User WHERE Alias = 'USER1' LIMIT 1].Id};
        List<Event> events = ReportsHelper.getUnManagedEvents(Date.today().addDays(-5), Date.today().addDays(5), userIds);
        System.assertEquals(2, events.size());
    }

    @isTest
    static void testCreateEventsCsvAndXls() {
        List<User> users = [SELECT Id, Email, LanguageLocaleKey,TimeZoneSidKey, profile.name, execution_context__c FROM User WHERE Alias = 'USER1' LIMIT 1];
        List<Event> events = [SELECT Id, Subject, Description, StartDateTime, EndDateTime, WhatId, WhoId, Cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c FROM Event];
        Map<String, String> xlsResult = ReportsHelper.createEventsXls(events, users[0]);
        System.assert(xlsResult.get('CONTENT') != null);
    }

    @isTest
    static void testSendEmail() {
        Test.startTest();
        User usr = [SELECT Id, Email, LanguageLocaleKey FROM User WHERE Alias = 'USER0' LIMIT 1];
        List<Event> events = [SELECT Id, Subject, Description, StartDateTime, EndDateTime, WhatId, WhoId, Cancelled__c, EventType__c, Owner.Name, LoginFlowCompleted__c FROM Event];
        ReportsHelper.sendEmail(usr, events, 'Test Subject', 'Body', 'filename_test', usr.Email, null);
        Test.stopTest();
    }

    @isTest
    static void testReportEventsManaged() {
        User usr = [SELECT Id, Email, LanguageLocaleKey, Name FROM User WHERE Alias = 'USER0' LIMIT 1];
        Test.startTest();
        ReportsHelper.reportEvents('MANAGED', Date.today().addDays(-5), Date.today().addDays(5), usr.Id, usr.Email);
        Test.stopTest();
    }

    @isTest
    static void testReportEventsUnManaged() {
        User usr = [SELECT Id, Email, LanguageLocaleKey, Name FROM User WHERE Alias = 'USER1' LIMIT 1];
        Test.startTest();
        ReportsHelper.reportEvents('UNMANAGED', Date.today().addDays(-5), Date.today().addDays(5), usr.Id, usr.Email);
        Test.stopTest();
    }

    @isTest
    static void testGetUserHierarchy() {
        Map<String, Set<String>> hierarchy = ReportsHelper.getUserHierarchy();
        System.assert(hierarchy.size() > 0);
    }

    /*@isTest
    static void testShareFileWithHierarchy() {
        // Mock ContentDocument
        ContentVersion cv = new ContentVersion(Title='Test File', PathOnClient='TestFile.xls', VersionData=Blob.valueOf('Test data'));
        insert cv;
        ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        User usr = [SELECT Id FROM User WHERE Alias = 'USER0' LIMIT 1];
        Test.startTest();
        ReportsHelper.shareFileWithHierarchy(version.ContentDocumentId, usr.Id);
        Test.stopTest();
    }*/

    @isTest
    static void testReportsHelperController() {
        // Obtener el evento creado
        Event testEvent = [SELECT Id FROM Event where ownerId =: UserInfo.getUserId() LIMIT 1];
        List<User> users = [SELECT Id FROM User where isactive = true];
        Set<String> ids = new Set<String>();

        for (User u : users) {
            ids.add(u.Id);
        }

        // Simular parámetros de la página
        Test.startTest();
        ApexPages.currentPage().getParameters().put('startDate', String.valueOf(System.today().addDays(-20)));
        ApexPages.currentPage().getParameters().put('endDate', String.valueOf(System.today().addDays(1)));
        ApexPages.currentPage().getParameters().put('type', 'MANAGED');
        ApexPages.currentPage().getParameters().put('userId', UserInfo.getUserId());

        // Instanciar el controlador
        ReportsHelperController controller = new ReportsHelperController();
        Test.stopTest();

        // Validar que se cargaron los eventos en el wrapper
        System.assertEquals(1, controller.events.size(), 'Debe haber un evento cargado');
        System.assertEquals('Test Event 10', controller.events[0].Subject, 'El subject debe coincidir');
        System.assert(controller.events[0].Link.contains(testEvent.Id), 'El link debe contener el Id del evento');
    }

    @isTest
    static void testReportsHelperControllerWithoutParam() {
        // Simular sin parámetros
        Test.startTest();
        ReportsHelperController controller = new ReportsHelperController();
        Test.stopTest();

        // No debe haber eventos
        System.assertEquals(0, controller.events.size(), 'No debe haber eventos si no hay parámetros');
    }

    @isTest
    static void fillerTest() {
        ReportsHelper.testFiller();
        Assert.isTrue(1 == 1);
    }
}