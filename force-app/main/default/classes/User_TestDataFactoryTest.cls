@isTest
public with sharing class User_TestDataFactoryTest {
    @isTest
    static void createUsers_EN() {
        List<User> usersBefore = [SELECT Id FROM User];
        List<User> userList = new List<User>();
        Map<String, Object> fieldsToAdd = new Map<String, Object> {'LocaleSidKey' => 'en_US'};

        userList.addAll(User_TestDataFactory.createUsers(2, new List<String>{'en_US'}));
        userList.addAll(User_TestDataFactory.createUsers(2, fieldsToAdd));
        userList.addAll(User_TestDataFactory.createUsersNoAdmin(2, new List<String>{'en_US'}));
        insert userList;
        
        List<User> usersAfter = [SELECT Id FROM User];
        
        System.assert(usersAfter.size() == (usersBefore.size() + 4), 'Users not created correctly');
    }
    
    @isTest
    static void createUsers_ES() {
        List<User> usersBefore = [SELECT Id FROM User];
        List<User> userList = new List<User>();
        Map<String, Object> fieldsToAdd = new Map<String, Object> {'LocaleSidKey' => 'es_ES'};
        
        userList.addAll(User_TestDataFactory.createUsers(2, new List<String>{'es_ES'}));
        userList.addAll(User_TestDataFactory.createUsers(2, fieldsToAdd));
        userList.addAll(User_TestDataFactory.createUsersNoAdmin(2, new List<String>{'es_ES'}));
        insert userList;
        
        List<User> usersAfter = [SELECT Id FROM User];
        
        System.assert(usersAfter.size() == (usersBefore.size() + 4), 'Users not created correctly');
    }
    
    @isTest
    static void createUsers_FR() {
        List<User> usersBefore = [SELECT Id FROM User];
        List<User> userList = new List<User>();
        Map<String, Object> fieldsToAdd = new Map<String, Object> {'LocaleSidKey' => 'fr_FR'};
        
        userList.addAll(User_TestDataFactory.createUsers(2, new List<String>{'fr_FR'}));
        userList.addAll(User_TestDataFactory.createUsers(2, fieldsToAdd));
        userList.addAll(User_TestDataFactory.createUsersNoAdmin(2, new List<String>{'fr_FR'}));
        insert userList;
        
        List<User> usersAfter = [SELECT Id FROM User];

        System.assert(usersAfter.size() == (usersBefore.size() + 4), 'Users not created correctly');
    }
}