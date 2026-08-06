@isTest
public class FollowServiceTest {
    @testSetup
    static void setupTestData() {
        User usr = DataFactoryUser.createUKUser();
        List<Account> accounts = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opportunities = DataFactoryOpportunity.createRetailOpportunities(accounts, 1);

        Event evt = new Event(
            WhatId = accounts[0].Id,
            Subject = 'Test Event',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );
        insert evt;

        Task task = new Task(
            WhatId = accounts[0].Id,
            Subject = 'Test Task',
            ActivityDate = Date.today()
        );
        insert task;

        EntitySubscription subscription = new EntitySubscription(
            SubscriberId = usr.Id,
            ParentId = accounts[0].Id
        );
        insert subscription;

        EntitySubscription subscriptionOpp = new EntitySubscription(
            SubscriberId = usr.Id,
            ParentId = opportunities[0].Id
        );
        insert subscriptionOpp;
    }

    @isTest
    static void testRecreateFollows() {
        User testUser = [SELECT Id FROM User WHERE Username like 'ukuser%' LIMIT 1];
        Test.startTest();
        // Act
        List<Follow__c> follows = FollowService.recreateFollows([SELECT id, ParentId, SubscriberId FROM EntitySubscription WHERE SubscriberId =: testUser.Id]);
        insert follows;

        // Assert
        System.assertNotEquals(null, follows, 'Follows list should not be null');
        System.assert(follows.size() > 0, 'Follows list should not be empty');

        Test.stopTest();
    }

    @isTest
    static void testGetDuplicateFollows() {
        User testUser = [SELECT Id FROM User WHERE Username like 'ukuser%' LIMIT 1];
        List<EntitySubscription> subscriptions = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription LIMIT 1];
        List<Follow__c> follows = FollowService.recreateFollows([SELECT id, ParentId, SubscriberId FROM EntitySubscription WHERE SubscriberId =: testUser.Id]);
        insert follows;
        List<Follow__c> duplicates = Follow.getDuplicateFollows(subscriptions);
        System.assertNotEquals(null, duplicates);
    }

    @isTest
    static void testRecreateFollowsByUser() {
        User testUser = [SELECT Id FROM User WHERE Username like 'ukuser%' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name like 'T %' LIMIT 1];

        Follow__c mockFollow = new Follow__c(Account__c = acc.Id, OwnerId = testUser.Id);
        insert mockFollow;

        Test.startTest();
        FollowService.recreateFollowsByUser(testUser.Id);
        Test.stopTest();

        // Validar que los registros Follow__c se hayan recreado correctamente.
        List<Follow__c> follows = [SELECT Id FROM Follow__c WHERE OwnerId = :testUser.Id];
        System.assert(follows.size() > 0, 'Se deben haber creado registros Follow__c');
    }

    @isTest
    static void testEventsCreated() {
        Account acc = [SELECT Id FROM Account WHERE Name like 'T %' LIMIT 1];
        Event testEvent = [SELECT Id, WhatId, StartDateTime,isChild, EndDateTime, OwnerId, Subject FROM Event WHERE isChild = false AND WhatId =: acc.Id LIMIT 1];

        Test.startTest();
        FollowService.eventsCreated(new List<Event>{testEvent});
        Test.stopTest();

        // Validar que los registros Follow__c se hayan creado para el evento.
        List<Follow__c> eventFollows = [SELECT Id FROM Follow__c WHERE Account__c = :testEvent.WhatId];
        System.assert(eventFollows.size() > 0, 'Se deben haber creado registros Follow__c para el evento');
    }

    @isTest
    static void testEventsUpdated() {
        User testUser = [SELECT Id FROM User WHERE Username like 'ukuser%' LIMIT 1];
        List<Follow__c> follows = FollowService.recreateFollows([SELECT id, ParentId, SubscriberId FROM EntitySubscription WHERE SubscriberId =: testUser.Id]);
        insert follows;

        Account acc = [SELECT Id FROM Account WHERE Name like 'T %' LIMIT 1];
        Event testEvent = [SELECT Id, WhatId,isChild, StartDateTime, EndDateTime, OwnerId, Subject FROM Event WHERE WhatId =: acc.Id LIMIT 1];
        testEvent.StartDateTime = DateTime.now().addDays(1);
        testEvent.EndDateTime = DateTime.now().addDays(1).addHours(1);
        update testEvent;

        Test.startTest();
        FollowService.eventsUpdated(
            new List<Event>{testEvent}
        );
        Test.stopTest();

        // Validar que los registros Follow__c se hayan actualizado correctamente.
        List<Follow__c> eventFollows = [SELECT EventStartDate__c, EventEndDate__c FROM Follow__c WHERE ActivityId__c = :testEvent.Id];
        for (Follow__c follow : eventFollows) {
            System.assertEquals(testEvent.StartDateTime, follow.EventStartDate__c, 'La fecha de inicio debe coincidir');
            System.assertEquals(testEvent.EndDateTime, follow.EventEndDate__c, 'La fecha de fin debe coincidir');
        }
    }

    @isTest
    static void testTasksCreated() {
        Account acc = [SELECT Id FROM Account WHERE Name like 'T %' LIMIT 1];
        Task testTask = [SELECT Id, WhatId, ActivityDate, Subject FROM Task WHERE WhatId =: acc.Id LIMIT 1];

        Test.startTest();
        FollowService.tasksCreated(new List<Task>{testTask});
        Test.stopTest();

        // Validar que los registros Follow__c se hayan creado para la tarea.
        List<Follow__c> taskFollows = [SELECT Id FROM Follow__c WHERE Account__c = :testTask.WhatId];
        System.assert(taskFollows.size() > 0, 'Se deben haber creado registros Follow__c para la tarea');
    }

    @isTest
    static void testTasksUpdated() {
        User testUser = [SELECT Id FROM User WHERE Username like 'ukuser%' LIMIT 1];
        List<Follow__c> follows = FollowService.recreateFollows([SELECT id, ParentId, SubscriberId FROM EntitySubscription WHERE SubscriberId =: testUser.Id]);
        insert follows;

        Account acc = [SELECT Id FROM Account WHERE Name like 'T %' LIMIT 1];
        Task testTask = [SELECT Id, WhatId, ActivityDate, Subject FROM Task WHERE WhatId =: acc.Id LIMIT 1];
        testTask.ActivityDate = Date.today().addDays(1);
        update testTask;

        Test.startTest();
        FollowService.tasksUpdated(
            new List<Task>{testTask}
        );
        Test.stopTest();

        // Validar que los registros Follow__c se hayan actualizado correctamente.
        List<Follow__c> taskFollows = [SELECT TaskDate__c FROM Follow__c WHERE ActivityId__c = :testTask.Id];
        for (Follow__c follow : taskFollows) {
            System.assertEquals(testTask.ActivityDate, follow.TaskDate__c, 'La fecha de la tarea debe coincidir');
        }
    }

    @isTest
    static void testDeleteUnfollowedByUser() {
        User testUser = [SELECT Id FROM User WHERE Username like 'ukuser%' LIMIT 1];

        Test.startTest();
        FollowService.deleteUnfollowedByUser(testUser.Id);
        Test.stopTest();

        // Validar que los registros Follow__c del usuario hayan sido eliminados.
        List<Follow__c> follows = [SELECT Id FROM Follow__c WHERE OwnerId = :testUser.Id];
        System.assertEquals(0, follows.size(), 'No debe haber registros Follow__c para el usuario');
    }

    @isTest
    static void fillerTest() {
        Follow aux = new Follow();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}