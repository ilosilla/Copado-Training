@isTest
public with sharing class UsersSelectorTest {

    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryUser.autoInsert = false;
        List<User> users = DataFactoryUser.createUKUsers(10);
        users[0].kunnr__c = '500000';
        insert users;        
    }

    @isTest
    private static void selectById() {
        Set<Id> usersIds = new Set<id>();
        for(User l : [Select Id from User LIMIT 10]) {
            usersIds.add(l.id);
        }
        UsersSelector selector = new UsersSelector();
        List<User> result = selector.selectById(usersIds);
        System.assertEquals(10, result.size(), '10 users expected!');
    }

    @isTest
    private static void selectByIdSingle() {
        User l = [Select Id from User LIMIT 1];
        User result = new UsersSelector().selectById(l.Id);
        System.assert( result != null, 'No ha encontrado el ususario');
    }

    @isTest private static void selectByRepCode() {
        List<User> users = new UsersSelector().selectByRepCode(new Set<String>{'500000'});
        System.assertEquals(1, users.size(), 'A user should have been found per rep code');
    }

}