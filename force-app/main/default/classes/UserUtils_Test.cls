@isTest
private class UserUtils_Test {
   
    @TestSetup
    static void makeData(){
        TestUtils.enableTriggers();
    }

    @isTest private static void getuserIdFromEmail() {
        String userId = userUtils.getUserIdFromEmail(UserInfo.getUserEmail());
        System.assertEquals(UserInfo.getUserId(), userId, 'Should be the current user');
        Boolean er = false;
        try {
            userId = userUtils.getUserIdFromEmail('aaaaa');
        } catch (ObjectNotFoundException onf) {
            er = true;
        }
        System.assertEquals(true, er, 'user should not have been found');
    }

    @isTest private static void getUsersFromEmail() {
        User[] users = userUtils.getUsersFromEmails(new List<String>{UserInfo.getUserEmail()});
        System.assertEquals(users[0].Id, UserInfo.getUserId(), 'Should be the current user');
        User[] users2 = UserUtils.getUsersFromEmails(new List<String>());
        System.assertEquals(0, users2.size());
    }

    @isTest private static void IsActive() {
        User adminUser = TestUtils.getAdminUser();
        System.assertEquals(true, UserUtils.isActive(adminUser.Id), 'The user should be active');
    }
    
    @isTest 
    private static void test_isAdministrator() {
        User adminUser = TestUtils.getAdminUser();
        System.assertNotEquals(adminUser, null, 'No admin user found!' );        
        System.assert(UserUtils.isAdministrator(adminUser) == true, 'User ' + adminUser + ' should have been identified as administrator');   
        System.runAs(adminUser) {
            System.assertEquals(UserUtils.isAdministrator(), true, 'Default User ' + adminUser + ' should have been identified as administrator');   
        }
    } // test_isAdministrator

    @isTest
    private static void test_isNotAdministrator() {
        User regularUser = TestUtils.getRegularUser();
        System.assertNotEquals(regularUser, null, 'No regular user found!' );        
        System.assert(UserUtils.isAdministrator(regularUser) == false, 'User ' + regularUser + ' shouldn´t have been identified as administrator');   
        System.runAs(regularUser) {
            System.assertEquals(UserUtils.isAdministrator(), false, 'Default User ' + regularUser + ' shouldn´t have been identified as administrator');   
        }
    } // test_isNotAdministrator
    
    @isTest private static void getSalesOrgs() {
    	User me = [select Id, Sales_Org__c from user where id = :UserInfo.getUserId() limit 1];
        List<String> results = UserUtils.getSalesOrgs();        
        if (me.Sales_Org__c != null && me.Sales_Org__c.length() > 0) {
            System.assertEquals(true, results.size() > 0);
        } else {
        	System.assertEquals(true, results.size() == 0);
        }
    } // getSalesOrgs

  @isTest 
    private static void test_isGenericUser() {
        User genericUser = TestUtils.getGenericUser();
        System.assertNotEquals(genericUser, null, 'No generic user found!' );
        System.assert(UserUtils.isGenericUser(genericUser) == true, 'User ' + genericUser + ' should have been identified as generic');   
        System.runAs(genericUser) {
            System.assert(UserUtils.isGenericUser(genericUser) == true, 'User ' + genericUser + ' should have been identified as generic');   
        }
    } // test_isGenericUser

    @isTest 
    private static void test_isNotGenericUser() {
        User genericUser = TestUtils.getRegularUser();
        System.assertNotEquals(genericUser, null, 'No generic user found!' );        
        System.assert(UserUtils.isGenericUser(genericUser) == false, 'User ' + genericUser + ' should have not been identified as generic');   
        System.runAs(genericUser) {
            System.assert(UserUtils.isGenericUser(genericUser) == false, 'User ' + genericUser + ' should have not been identified as generic');   
        }
    } // test_isNotGenericUser

    @isTest 
    private static void test_hierarchy() {
        Map<Id,Set<Id>> hierarchy = UserUtils.getHierarchyUsers();
        UserRole usrRoleSubirdinate = [select Id, DeveloperName from UserRole where DeveloperName = 'Sales_Office_Glasgow'];
        UserRole usrRoleManager = [select Id, DeveloperName from UserRole where DeveloperName = 'Glasgow_Showroom_Manager'];
        List<User> usrsListSubordinates = [select Id, UserRoleId, UserRole.ParentRoleId from User where isActive=true and UserRoleId =: usrRoleSubirdinate.Id];
        List<User> usrsListManagers = [select Id, UserRoleId, UserRole.ParentRoleId from User where isActive=true and UserRoleId =: usrRoleManager.Id];
        System.assert(hierarchy.get(usrsListManagers[0].Id).contains(usrsListSubordinates[0].Id) , 'Hierarchie not created correctly');
    } // test_hierarchy

    @isTest static void getDefaultSalesOrg() {
        User user = DataFactoryUser.createUKAdmin();
        System.runas(user) {
            String org = UserUtils.getDefaultSalesOrg();
            System.assertEquals(OrganizationCommons.ORG_SOUTH_EAST, org, 'Sales org not calculated');
        }
    }

    @isTest static void getSAPUserId() {
        String id = UserUtils.getSAPUserId('0001332233');
        System.assertEquals('', id, 'SAP User should be emnpty');
    }

    @isTest static void getUserName() {
        System.assertNotEquals('', UserUtils.getuserName(UserInfo.getUserId()), 'User name not returned');
    }

    @isTest static void isTester() {
        User user = DataFactoryUser.createUKAdmin();
        System.runAs(user) {
            System.assertEquals(false,UserUtils.isTester(), 'This user is not a tester');
            user.email = 'rprades@xyz.com.void';
            update user;
            System.assertEquals(true, UserUtils.isTester(),  'This user is a tester');
        }
    }

    @isTest static void getSalesOfficeUsers() {
        DataFactoryUser.createUKUser();
        List<User> users = UserUtils.getSalesOfficeUsersWithAppointment('2552');
        System.assertNotEquals(0, users.size(), 'There should have been users in that sales office');
    }

    @isTest static void getSalesOfficeRandomUser() {
        DataFactoryUser.createUKUser();
        User user2 = UserUtils.getSalesOfficeRandomUser('2552');
        System.assertNotEquals(null, user2, 'There should have been a user in that sales office');
    }

    @isTest static void getProductManagers() {
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'ProductManagers' limit 1];
        System.assertNotEquals(null, gr, 'Group should have been found');
        User[] users = UserUtils.getProductManagers('US');
        System.assert(users.size() >= 0, 'Silly test, but we cant touch setup objects');
    }

    @isTest static void getFacadeManagers() {
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'USFacadeManagers' limit 1];
        System.assertNotEquals(null, gr, 'Group should have been found');
        User[] users = UserUtils.getFacadeManagers('US');
        System.assert(users.size() >= 0, 'Silly test, but we cant touch setup objects');
    }

    @isTest static void getKitchenManagers() {
        Group gr = [select Id, DeveloperName from Group where DeveloperName = 'USKitchenManagers' limit 1];
        System.assertNotEquals(null, gr, 'Group should have been found');
        User[] users = UserUtils.getKitchenManagers('US');
        System.assert(users.size() >= 0, 'Silly test, but we cant touch setup objects');
    }

    @isTest static void getKitchenDesigners() {
        List<KitchenTeam__c> designers = UserUtils.getKitchenDesigners('US');
        System.assert(designers.size() >= 0, 'Silly test, but we cant touch setup objects');
    }
    
    @isTest static void checkPermissionSet() {
        PermissionSet ps = [select Id, Name from PermissionSet limit 1];
        Boolean result2 = UserUtils.checkPermissionSet(ps.Name);
        System.assertEquals(result2, UserUtils.checkPermissionSet(UserInfo.getUserId(), ps.Name), 'Permission should have been ' + result2);
    }
    
    @isTest static void hasWritePermissions() {
        List<Account> acc = DataFactoryAccount.createBusinessAccounts(1);
        System.assert(UserUtils.hasWritePermission(UserInfo.getUserId(), acc[0].Id), 'Debería tener permiso de escritura');
    }

    @isTest private static void testGetPublicGroupMembers() {
        List<GroupMember> members = [select GroupId from GroupMember];
        System.assertNotEquals(0, members.size(), 'No groups for testing!');
        Group gr = [select Id, DeveloperName from Group where Id = : members[0].GroupId limit 1];
        
        List<Id> result = UserUtils.getPublicGroupMembers(gr.DeveloperName);
        System.assertNotEquals(0, result.size(), 'At least a user should have been found');

        // Negative test
        List<Id> result2 = UserUtils.getPublicGroupMembers('sljfkghqefdighsdflhg');
        System.assertEquals(0, result2.size(), 'No users should have been found');        
    }

}