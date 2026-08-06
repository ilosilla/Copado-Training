@isTest
public class DvsEmailsTest {
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingPostalCode = 'LA22 9NZ',
            BillingCountryCode = 'GB',
            VAT_Number__c = '123456789',
            VAT_Number_2__c = '987654321'
        );
        insert testAccount;

        Group[] groups = [select Id, DeveloperName from Group where DeveloperName = 'accounting_department_fr'];
        if (groups.size() == 0) {
            Group test = new Group();
            test.Name = 'accounting_department_fr';
            insert test;

            GroupMember member = new GroupMember();
            member.GroupId = test.Id;
            member.UserOrGroupId = UserInfo.getUserId();
            insert member;
        }
    }

    @isTest
    static void testSendDvsConfirmationRequest() {
        // Arrange
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User user = [SELECT Id FROM User LIMIT 1];
        Map<String, String> mockCompany = new Map<String, String>{
            'GLOBAL_NAME_FIELD_LABEL' => 'Mock Company Name',
            'GLOBAL_STREET_FIELD_LABEL' => 'Mock Street',
            'GLOBAL_POSTALCODE_FIELD_LABEL' => '12345',
            'GLOBAL_CITY_FIELD_LABEL' => 'Mock City',
            'GLOBAL_COUNTRY_FIELD_LABEL' => 'Mock Country',
            'FR_SIRET_FIELD_LABEL' => '123456789',
            'FR_SIREN_FIELD_LABEL' => '987654321'
        };

        // Act
        Test.startTest();
        DvsEmails.sendDvsConfirmationRequest(mockCompany, acc.Id, 'VALID');
        Test.stopTest();

        // Assert
        // Verify that emails are sent correctly using assert statements or email logs
    }

    @isTest
    static void testSendDvsConfirmationRequestUnknown() {
        // Arrange
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, String> mockCompany = new Map<String, String>();

        // Act
        Test.startTest();
        DvsEmails.sendDvsConfirmationRequest(mockCompany, acc.Id, 'UNKNOWN');
        Test.stopTest();

        // Assert
        // Verify that emails are sent correctly using assert statements or email logs
    }

    @isTest
    static void testSendDvsConfirmation() {
        // Arrange
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User user = [SELECT Id FROM User LIMIT 1];

        // Act
        Test.startTest();
        DvsEmails.sendDvsConfirmation(acc.Id, user.Id);
        Test.stopTest();

        // Assert
        // Verify that emails are sent correctly using assert statements or email logs
    }

}