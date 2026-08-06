/**
 * Purpose: Create ContactPointAddress test data with a fluent second-generation factory.
 *
 * Design notes:
 * - The factory builds ContactPointAddress records in memory first and inserts them only on create().
 * - If no parent account is provided, the factory creates one automatically during buildContext().
 * - Variants provide convenient country-specific defaults while still allowing manual changes before insert.
 *
 * Usage examples:
 * - new TestFactoryContactPointAddress().build().createSingle();
 * - new TestFactoryContactPointAddress().withVariant(TestFactoryContactPointAddress.VARIANT_SHIPPING_US).build(2).create();
 * - TestFactoryContactPointAddress factory = new TestFactoryContactPointAddress().withAccountId(acc.Id);
 * - factory.build();
 * - ContactPointAddress address = factory.getSingleAddress();
 * - address.City = 'Waldwick';
 * - factory.createSingle();
 */
@IsTest
public class TestFactoryContactPointAddress extends AbstractTestFactory {

    public static final String VARIANT_SHIPPING_GB = 'SHIPPING_GB';
    public static final String VARIANT_SHIPPING_US = 'SHIPPING_US';

    private Id thisAccountId;
    private String thisToken;

    public TestFactoryContactPointAddress withAccountId(Id accountId) {
        this.thisAccountId = accountId;
        return this;
    }

    public List<ContactPointAddress> getAddresses() {
        return this.toAddresses(this.getRecords());
    }

    public ContactPointAddress getSingleAddress() {
        return (ContactPointAddress) this.getSingleRecord();
    }

    /* ========================================================= */
    /* PROTECTED HOOKS                                           */
    /* ========================================================= */

    protected override void buildContext() {
        this.thisToken = TestUtils.generateRandomString(8);
        if (String.isBlank(this.variantName)) {
            this.variantName = VARIANT_SHIPPING_GB;
        }
        if (this.thisAccountId == null) {
            Account account = (Account) new TestFactoryAccount().build().createSingle();
            this.thisAccountId = account.Id;
        }
    }

    protected override SObject buildRecord(Integer index) {
        if (this.variantName == VARIANT_SHIPPING_US) {
            return this.buildShippingUsAddress(index);
        }
        return this.buildShippingGbAddress(index);
    }

    /* ========================================================= */
    /* PRIVATE METHODS                                           */
    /* ========================================================= */

    private ContactPointAddress buildShippingGbAddress(Integer index) {
        return new ContactPointAddress(
            AddressType = 'Shipping',
            Name = 'Test address ' + this.thisToken + ' #' + index,
            ParentId = this.thisAccountId,
            City = 'Ilkley',
            CountryCode = 'GB',
            PostalCode = 'LS9 9EE',
            StateCode = 'SE',
            Street = index + ' The Grove'
        );
    }

    private ContactPointAddress buildShippingUsAddress(Integer index) {
        return new ContactPointAddress(
            AddressType = 'Shipping',
            Name = 'Test address ' + this.thisToken + ' #' + index,
            ParentId = this.thisAccountId,
            City = 'Sonoma',
            CountryCode = 'US',
            PostalCode = '95476',
            StateCode = 'CA',
            Street = index + ' Main Street'
        );
    }

    private List<ContactPointAddress> toAddresses(List<SObject> source) {
        List<ContactPointAddress> result = new List<ContactPointAddress>();
        for (SObject record : source) {
            result.add((ContactPointAddress) record);
        }
        return result;
    }

    /* ========================================================= */
    /* TEST METHODS                                              */
    /* ========================================================= */

    @IsTest
    private static void buildAndCreateSingleTest() {
        TestFactoryContactPointAddress factory = new TestFactoryContactPointAddress();
        factory.build();

        ContactPointAddress address = factory.getSingleAddress();
        System.assertNotEquals(null, address, 'A built address should be available before insert.');
        System.assertEquals('GB', address.CountryCode, 'The default variant should create GB addresses.');
        System.assertNotEquals(null, address.ParentId, 'The factory should create a parent account automatically when needed.');
        System.assertEquals(null, address.Id, 'The record should not be inserted before createSingle().');

        ContactPointAddress savedAddress = (ContactPointAddress) factory.createSingle();
        System.assertNotEquals(null, savedAddress.Id, 'createSingle() should insert the built address.');
    }

    @IsTest
    private static void accountAndVariantTest() {
        TestFactoryAccount accountFactory = new TestFactoryAccount();
        accountFactory.withVariant(TestFactoryAccount.VARIANT_TRADE_US);
        Account account = (Account) accountFactory.build().createSingle();

        TestFactoryContactPointAddress factory = new TestFactoryContactPointAddress()
            .withAccountId(account.Id);
        factory.withVariant(VARIANT_SHIPPING_US);

        factory.build();
        ContactPointAddress address = factory.getSingleAddress();
        address.City = 'Waldwick';
        address.StateCode = 'NJ';

        System.assertEquals(account.Id, address.ParentId, 'The injected account should be used as the parent.');
        System.assertEquals('US', address.CountryCode, 'The US variant should set the country code.');
        System.assertEquals('NJ', address.StateCode, 'Manual changes should be preserved before insert.');

        ContactPointAddress savedAddress = (ContactPointAddress) factory.createSingle();
        System.assertNotEquals(null, savedAddress.Id, 'createSingle() should insert the modified address.');
    }
}