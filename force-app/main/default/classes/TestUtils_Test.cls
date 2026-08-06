/**
 * Author           Ramón prades
 * Description      Test class for TestUtils
 * Date             May 2020
 * History              
 */
@isTest
private class TestUtils_Test {

    @isTest private static void test_getAdminUser() {
        System.assert(TestUtils.getAdminUser() <> null, 'There must be at least a SYSADMIN in the system. Please check SystemSettings.adminProfiles');
    }
    
    @isTest private static void test_getRegularUser() {
        User user = TestUtils.getRegularUser();
        System.assert(TestUtils.getRegularUser() <> null, 'There must be at least a REGULAR USER in the system. Please check SystemSettings.adminProfiles');
    }

    @isTest private static void test_getGenericUser() {
        User user = TestUtils.getGenericUser();
        System.assert(TestUtils.getGenericUser() <> null, 'There must be at least a GENERIC USER in the system. Please check SystemSettings.genericUsers');
    }

    @isTest private static void test_generateRandomString() {
        String str = TestUtils.generateRandomString(12);
        System.assertEquals(12, str.length());
    }   

    @isTest private static void test_getPicklistOption() {
        String option = TestUtils.getPicklistOption(Account.Industry);
        System.assertNotEquals(null, option, 'An option should have been found for field Account.Industry');
    }
}