@isTest
public class UserAdditionalInfoTest {
    @testSetup
    static void setupTestData() {
        // Create test User
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];


        // Create test Accounts
        List<Account> testAccounts = DataFactoryAccount.createBusinessAccounts(2);

        // Create UserAdditionalInfo__c for managed accounts
        UserAdditionalInfo__c managedAccount = new UserAdditionalInfo__c(
            User__c = testUser.Id,
            InfoType__c = UserAdditionalInfo.DVSMANAGEDACCOUNTS,
            Value1__c = testAccounts[0].Id,
            Value2__c = String.valueOf(Date.today())
        );
        insert managedAccount;
    }

    @isTest
    static void testSetLastPopupTime() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Act
        Test.startTest();
        Boolean result = UserAdditionalInfo.setLastPopupTime(testUser.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'The method should return true.');
        UserAdditionalInfo__c updatedInfo = [SELECT Value1__c FROM UserAdditionalInfo__c 
                                             WHERE User__c = :testUser.Id AND InfoType__c = :UserAdditionalInfo.POPUPTIMEOPTION LIMIT 1];
        System.assertNotEquals(null, updatedInfo, 'The popup time record should exist.');
        System.assertNotEquals('', updatedInfo.Value1__c, 'The Value1__c field should be updated.');
    }

    @isTest
    static void testSetDvsAccountsManaged() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Act
        Test.startTest();
        Boolean result = UserAdditionalInfo.setDvsAccountsManaged(testUser.Id, testAccount.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'The method should return true.');
        UserAdditionalInfo__c managedAccount = [SELECT Value1__c, Value2__c FROM UserAdditionalInfo__c 
                                                WHERE User__c = :testUser.Id AND InfoType__c = :UserAdditionalInfo.DVSMANAGEDACCOUNTS LIMIT 1];
        System.assertNotEquals(null, managedAccount, 'The managed account record should exist.');
        System.assertEquals(testAccount.Id, managedAccount.Value1__c, 'The account ID should match.');
        System.assertEquals(String.valueOf(Date.today()), managedAccount.Value2__c, 'The Value2__c field should match today\'s date.');
    }

    @isTest
    static void testGetLastPopupTime() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Create UserAdditionalInfo__c for popup time
        UserAdditionalInfo__c popupTime = new UserAdditionalInfo__c(
            User__c = testUser.Id,
            InfoType__c = UserAdditionalInfo.POPUPTIMEOPTION,
            Value1__c = String.valueOf(Datetime.now().addDays(-1))
        );
        insert popupTime;

        // Act
        Test.startTest();
        UserAdditionalInfo__c lastPopupTime = UserAdditionalInfo.getLastPopupTime(testUser.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, lastPopupTime, 'The last popup time record should exist.');
        System.assertEquals(UserAdditionalInfo.POPUPTIMEOPTION, lastPopupTime.InfoType__c, 'The info type should match.');
    }

    @isTest
    static void testGetDvsAccountsManaged() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Act
        Test.startTest();
        List<Account> managedAccounts = UserAdditionalInfo.getDvsAccountsManaged(testUser.Id, Date.today());
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, managedAccounts, 'The managed accounts list should not be null.');
        System.assertEquals(1, managedAccounts.size(), 'There should be one managed account.');
    }

    @isTest
    static void testGetAllInfo() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Create UserAdditionalInfo__c for popup time
        UserAdditionalInfo__c popupTime = new UserAdditionalInfo__c(
            User__c = testUser.Id,
            InfoType__c = UserAdditionalInfo.POPUPTIMEOPTION,
            Value1__c = String.valueOf(Datetime.now().addDays(-1))
        );
        insert popupTime;

        // Act
        Test.startTest();
        UserAdditionalInfo.UAIAllInfoDTO allInfo = UserAdditionalInfo.getAllInfo(testUser.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, allInfo, 'The allInfo object should not be null.');
        System.assertNotEquals(null, allInfo.lastPopupTime, 'The lastPopupTime field should not be null.');
        System.assertNotEquals(null, allInfo.dvsAccountsManaged, 'The dvsAccountsManaged field should not be null.');
    }
}