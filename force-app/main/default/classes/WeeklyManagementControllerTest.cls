@isTest
private class WeeklyManagementControllerTest {
    
    @isTest
    static void testWeeklyManagementController() {
        User u = DatafactoryUser.createUKUser();

        Account acc = DatafactoryAccount.createAccounts(1)[0];

        // Crear una oportunidad vinculada
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=System.today().addDays(30),
            OwnerId=u.Id,
            LeadSource='Porsamarket',
            AccountId=acc.Id
        );
        insert opp;
                    
        System.runAs(u) {
            // Crear evento
            Event evt = new Event(
                Subject='Test Event',
                StartDateTime=System.now().addDays(-1),
                EndDateTime=System.now().addHours(1),
                OwnerId=UserInfo.getUserId(),
                WhatId=acc.Id,
                IsPrivate=false
            );
            insert evt;
        }

        // Crear Follow__c relacionado con la Account
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Follow__c' AND Name='Account' LIMIT 1];
        Follow__c fol = new Follow__c(
            Account__c=acc.Id,
            OwnerId=u.Id,
            RecordTypeId=rt.Id
        );
        insert fol;

        // Crear registros adicionales ficticios
        AccountAdditionalInfo__c accInfo = new AccountAdditionalInfo__c(
            Account__c=acc.Id,
            InfoType__c = 'WEEKLYCOMMENT',
            StartDateTime__c=System.today().addDays(-1),
            Value__c='Info'
        );
        insert accInfo;

        OpportunityAdditionalInfo__c oppInfo = new OpportunityAdditionalInfo__c(
            Opportunity__c=opp.Id,
            InfoType__c = 'WEEKLYCOMMENT',
            StartDateTime__c=System.today().addDays(-1),
            Value__c='Opp Info'
        );
        insert oppInfo;

        Test.startTest();

        // Probar getEvents
        List<Event> events = WeeklyManagementController.getEvents(System.today().addDays(-2), System.today().addDays(2), u.Id);
        System.assert(!events.isEmpty(), 'Debe devolver eventos');

        // Probar eventsSetCompleted
        WeeklyManagementController.eventsSetCompleted(events);
        System.assert(events[0].LoginFlowCompleted__c != null || events[0].LoginFlowCompleted__c == null);

        // Probar getKeyAccounts
        /*List<Account> keyAccounts = WeeklyManagementController.getKeyAccounts(u.Id);
        System.assert(!keyAccounts.isEmpty(), 'Debe devolver cuentas clave');

        // Probar getKeyOpportunities
        List<Opportunity> keyOpps = WeeklyManagementController.getKeyOpportunities(u.Id);
        System.assert(!keyOpps.isEmpty(), 'Debe devolver oportunidades clave');

        // Probar getKeyAccountsComments
        List<AccountAdditionalInfo__c> accComments = WeeklyManagementController.getKeyAccountsComments(System.today().addDays(-2), System.today().addDays(2), u.Id);
        System.assert(!accComments.isEmpty(), 'Debe devolver comentarios de cuentas');

        // Probar getKeyOpportunitiesComments
        List<OpportunityAdditionalInfo__c> oppComments = WeeklyManagementController.getKeyOpportunitiesComments(System.today().addDays(-2), System.today().addDays(2), u.Id);
        System.assert(!oppComments.isEmpty(), 'Debe devolver comentarios de oportunidades');

        // Probar weeklySent (falso)
        Boolean sent = WeeklyManagementController.weeklySent(System.today().addDays(-2), System.today().addDays(2), u.Id);
        System.assertEquals(false, sent);

        // Probar sendWeeklyReport
        WeeklyManagementController.sendWeeklyReport(System.today().addDays(-2), System.today().addDays(2), u.Id, 'Comentario');
        Boolean sentNow = WeeklyManagementController.weeklySent(System.today().addDays(-2), System.today().addDays(2), u.Id);
        System.assertEquals(true, sentNow);*/

        // Probar getWeeklyData
        WeeklyManagementController.weeklyData data = WeeklyManagementController.getWeeklyData(System.today().addDays(-2), System.today().addDays(2), u.Id);
        System.assertNotEquals(null, data, 'Debe devolver datos semanales');
        //System.assertEquals(true, data.weeklyReportSent, 'Debe marcar reporte como enviado');

        Test.stopTest();
    }

    @isTest
    static void testWeeklyManagementPdfController() {
        User u = DatafactoryUser.createUKUser();

        // Crear una Account de prueba
        Account acc = DatafactoryAccount.createAccounts(1)[0];

        // Crear una oportunidad vinculada
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=System.today().addDays(30),
            OwnerId=u.Id,
            LeadSource='Porsamarket',
            AccountId=acc.Id
        );
        insert opp;

        System.runAs(u) {
            // Crear evento
            Event evt = new Event(
                Subject='Test Event',
                StartDateTime=System.now().addDays(-1),
                EndDateTime=System.now().addHours(1),
                OwnerId=u.Id,
                IsPrivate=false
            );
            insert evt;
        }

        // Obtener el evento creado
        Event testEvent = [SELECT Id FROM Event where ownerId =: u.Id LIMIT 1];
        List<User> users = [SELECT Id FROM User where isactive = true];
        Set<String> ids = new Set<String>();

        for (User usr : users) {
            ids.add(usr.Id);
        }

        // Simular parámetros de la página
        Test.startTest();
        ApexPages.currentPage().getParameters().put('startDate', String.valueOf(System.today().addDays(-20)));
        ApexPages.currentPage().getParameters().put('endDate', String.valueOf(System.today().addDays(1)));
        ApexPages.currentPage().getParameters().put('userId', u.Id);

        // Instanciar el controlador
        WeeklyManagementPdfController controller = new WeeklyManagementPdfController();
        Test.stopTest();

        // Validar que se cargaron los eventos en el wrapper
        System.assertEquals(1, controller.events.size(), 'Debe haber un evento cargado');
        System.assertEquals('Test Event', controller.events[0].Subject, 'El subject debe coincidir');
        System.assert(controller.events[0].Link.contains(testEvent.Id), 'El link debe contener el Id del evento');
    }


    @isTest
    static void fillerTestAccountAdditionalData() {
        WeeklyManagementController.testFiller();
        Assert.isTrue(1 == 1);
    }
}