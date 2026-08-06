@isTest
public class PopupActionsServiceTest {
    @testSetup
    static void setupTestData() {
        // Create a test user
        User testUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];

        // Create test accounts
        DataFactoryAccount.autoInsert = false;
        List<Account> testAccounts = DataFactoryAccount.createBusinessAccounts(5);

        for (Account acc : testAccounts) {
            acc.BillingCountryCode = 'FR';
            acc.BillingPostalCode = '11123';
            acc.OwnerId = UserInfo.getUserId();       
        }
        insert testAccounts;
    }

    @isTest
    static void testCurrentUserData() {
        // Act
        Test.startTest();
        User currentUser = PopupActionsService.currentUserData();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, currentUser, 'The current user should not be null.');
        System.assertEquals(UserInfo.getUserId(), currentUser.Id, 'The returned user ID should match the current user.');
    }

    @isTest
    static void testGetNoManagedAccounts() {
        // Act
        Test.startTest();
        List<Account> noManagedAccounts = PopupActionsService.getNoManagedAccounts(3);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, noManagedAccounts, 'The returned account list should not be null.');
        System.assertEquals(0, noManagedAccounts.size(), 'The size of the returned list should match the requested number of records.');
        for (Account acc : noManagedAccounts) {
            System.assertEquals('FR', acc.BillingCountryCode, 'The accounts should have BillingCountryCode = "FR".');
            System.assertEquals(null, acc.DvsAction__c, 'The accounts should not have a DvsAction__c value.');
        }
    }

    @isTest
    static void testGetNoManagedAccounts_EmptyResult() {
        // Arrange
        // Create accounts that do not meet the criteria
        List<Account> unrelatedAccounts = DataFactoryAccount.createAccounts(5);

        for (Account acc : unrelatedAccounts) {
            acc.BillingCountryCode = 'GB';
            acc.BillingPostalCode = 'LA22 9NZ';
            acc.OwnerId = UserInfo.getUserId();
            acc.DvsAction__c = 'CONFIRMED';     
        }
        update unrelatedAccounts;

        // Act
        Test.startTest();
        List<Account> noManagedAccounts = PopupActionsService.getNoManagedAccounts(5);
        Test.stopTest();

        // Assert
        System.assertEquals(0, noManagedAccounts.size(), 'No accounts should be returned as none meet the criteria.');
    }
}