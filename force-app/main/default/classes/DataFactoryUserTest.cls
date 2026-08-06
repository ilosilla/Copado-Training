@isTest public with sharing class DataFactoryUserTest {

    @TestSetup private static void setup() {
        TestUtils.enableTriggers();
    }

    @isTest public static void createUKAdmin() {
        User admin = DataFactoryuser.createUKAdmin();
        System.assertNotEquals(null, admin, 'UK Admin User not created');
    }

    @isTest public static void createUKUser() {
        User usr = DataFactoryuser.createUKUser();
        System.assertNotEquals(null, usr, 'UK User not created');
    }

    @isTest public static void createUKUser2() {
        List<User> usrs = DataFactoryuser.createUKUsers(5);
        System.assertEquals(5, usrs.size(), 'UK User not created');
    }

}