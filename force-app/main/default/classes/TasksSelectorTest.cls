@isTest
public with sharing class TasksSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        List<Account> accs = DataFactoryAccount.createAccounts(10);
        Task newTask = new Task(TaskSubType = 'Email', WhatId = accs[0].Id, Subject = 'Test');
        insert newTask;
    }

    @isTest
    private static void selectById() {
        Set<Id> tasksIds = new Set<id>();
        for(Task l : [Select Id from Task]) {
            tasksIds.add(l.id);
        }

        List<Task> result = new TasksSelector().selectById(tasksIds);
        System.assertEquals(1, result.size(), '1 Tasks expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        Task evt = [Select Id from Task LIMIT 1];
        Task result = new TasksSelector().selectById(evt.Id);
        System.assert(result != null, 'No se ha encontrado el Task');
    }
}