/**
 * Purpose: Create Account test data with a fluent second-generation factory.
 *
 * Design notes:
 * - The factory builds Accounts in memory first and inserts them only on create().
 * - Variants provide convenient default data while still allowing manual changes before insert.
 * - The default variant follows the current trade account defaults used in DataFactoryAccount.
 *
 * Usage examples:
 * - new TestFactoryAccount().build().createSingle();
 * - new TestFactoryAccount().withVariant(TestFactoryAccount.VARIANT_TRADE_US).build(2).create();
 * - TestFactoryAccount factory = new TestFactoryAccount();
 * - factory.withVariant(TestFactoryAccount.VARIANT_PRIVATE_GB);
 * - factory.build();
 * - Account account = factory.getSingleAccount();
 * - account.PersonMailingCity = 'Leeds';
 * - factory.createSingle();
 */
@IsTest
public class TestFactoryAccount extends AbstractTestFactory {

    public static final String VARIANT_TRADE_GB = 'TRADE_GB';
    public static final String VARIANT_TRADE_US = 'TRADE_US';
    public static final String VARIANT_PRIVATE_GB = 'PRIVATE_GB';

    private String thisToken;

    public List<Account> getAccounts() {
        return this.toAccounts(this.getRecords());
    }

    public Account getSingleAccount() {
        return (Account) this.getSingleRecord();
    }

    /* ========================================================= */
    /* PROTECTED HOOKS                                           */
    /* ========================================================= */

    protected override void buildContext() {
        this.thisToken = TestUtils.generateRandomString(12);
        if (String.isBlank(this.variantName)) {
            this.variantName = VARIANT_TRADE_GB;
        }
    }

    protected override SObject buildRecord(Integer index) {
        if (this.variantName == VARIANT_TRADE_US) {
            return this.buildTradeUsAccount(index);
        }
        if (this.variantName == VARIANT_PRIVATE_GB) {
            return this.buildPrivateGbAccount(index);
        }
        return this.buildTradeGbAccount(index);
    }

    /* ========================================================= */
    /* PRIVATE METHODS                                           */
    /* ========================================================= */

    private Account buildTradeGbAccount(Integer index) {
        String postalCode = 'AB' + index + ' 3EH';
        if (index > 9) {
            postalCode = 'AB9 3EH';
        }

        return new Account(
            Name = 'T ' + this.thisToken + ' #' + index,
            RecordTypeId = RecordTypeLibrary.Account_TradeCustomer,
            Business_Email__c = 'test' + this.thisToken + index + '@test.c0m',
            BillingCountryCode = 'GB',
            BillingCity = 'London',
            BillingPostalCode = postalCode
        );
    }

    private Account buildTradeUsAccount(Integer index) {
        return new Account(
            Name = 'T ' + this.thisToken + ' #' + index,
            RecordTypeId = RecordTypeLibrary.Account_TradeCustomer,
            Business_Email__c = 'test' + this.thisToken + index + '@test.c0m',
            BillingCountryCode = 'US',
            BillingStateCode = 'CA',
            BillingCity = 'Sonoma',
            BillingPostalCode = '95476'
        );
    }

    private Account buildPrivateGbAccount(Integer index) {
        String postalCode = 'LS' + index + ' 3NZ';
        if (index > 9) {
            postalCode = 'LS9 3NZ';
        }

        return new Account(
            FirstName = 'John',
            LastName = 'Smith ' + this.thisToken + ' #' + index,
            Salutation = 'Dr.',
            RecordTypeId = RecordTypeLibrary.Account_PrivateCustomer,
            PersonEmail = 'test' + this.thisToken + index + '@test.c0m',
            PersonMailingCountryCode = 'GB',
            PersonMailingCity = 'Bristol',
            PersonMailingPostalCode = postalCode
        );
    }

    private List<Account> toAccounts(List<SObject> source) {
        List<Account> result = new List<Account>();
        for (SObject record : source) {
            result.add((Account) record);
        }
        return result;
    }

    /* ========================================================= */
    /* TEST METHODS                                              */
    /* ========================================================= */

    @IsTest
    private static void buildAndCreateSingleTest() {
        TestFactoryAccount factory = new TestFactoryAccount();
        factory.build();

        Account account = factory.getSingleAccount();
        System.assertNotEquals(null, account, 'A built account should be available before insert.');
        System.assertEquals('GB', account.BillingCountryCode, 'The default variant should create GB trade accounts.');
        System.assertEquals(null, account.Id, 'The record should not be inserted before createSingle().');

        Account savedAccount = (Account) factory.createSingle();
        System.assertNotEquals(null, savedAccount.Id, 'createSingle() should insert the built account.');
    }

    @IsTest
    private static void variantAndManualChangesTest() {
        TestFactoryAccount factory = new TestFactoryAccount();
        factory.withVariant(VARIANT_TRADE_US);

        factory.build();
        Account account = factory.getSingleAccount();
        account.BillingStateCode = 'NJ';
        account.BillingCity = 'Waldwick';

        System.assertEquals('US', account.BillingCountryCode, 'The US variant should set the country code.');
        System.assertEquals('NJ', account.BillingStateCode, 'Manual changes should be preserved before insert.');
        System.assertEquals('Waldwick', account.BillingCity, 'Manual changes should be preserved before insert.');

        Account savedAccount = (Account) factory.createSingle();
        System.assertNotEquals(null, savedAccount.Id, 'createSingle() should insert the modified account.');
    }
}