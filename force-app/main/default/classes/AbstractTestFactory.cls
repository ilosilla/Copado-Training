/**
 * Purpose: Base class for second-generation test factories.
 *
 * Design notes:
 * - The class separates record construction from persistence.
 * - Concrete factories can inject dependencies through withXxxId(...) methods and resolve them in buildContext().
 * - build(...) always replaces the previously built records.
 * - Built records can be modified before create() or createSingle() is called.
 *
 * Usage examples:
 * - new TestFactoryAccount().build().createSingle();
 * - new TestFactoryAccount().withVariant(TestFactoryAccount.VARIANT_TRADE_US).build(3).create();
 * - TestFactoryAccount factory = new TestFactoryAccount();
 * - factory.build(2);
 * - List<Account> accounts = factory.getAccounts();
 * - accounts[0].BillingCountryCode = 'US';
 * - factory.create();
 */
public abstract class AbstractTestFactory {

    protected List<SObject> records = new List<SObject>();
    protected String variantName;

    /* ========================================================= */
    /* PUBLIC API METHODS                                        */
    /* ========================================================= */

    public AbstractTestFactory build() {
        return this.build(1);
    }

    public AbstractTestFactory build(Integer count) {
        if (count == null || count <= 0) {
            throw new TestFactoryException('Build count must be greater than zero.');
        }

        this.buildContext();
        this.records = new List<SObject>();
        for (Integer i = 0; i < count; i++) {
            this.records.add(this.buildRecord(i));
        }
        return this;
    }

    public AbstractTestFactory withVariant(String variantName) {
        this.variantName = variantName;
        return this;
    }

    public List<SObject> create() {
        if (this.records.isEmpty()) {
            this.build();
        }

        insert this.records;
        return this.records;
    }

    public SObject createSingle() {
        List<SObject> records = this.create();
        if (records.size() != 1) {
            throw new TestFactoryException('createSingle() requires exactly one built record.');
        }

        return records[0];
    }

    public List<SObject> getRecords() {
        if (this.records.isEmpty()) {
            this.build();
        }

        return this.records;
    }

    public SObject getSingleRecord() {
        List<SObject> records = this.getRecords();
        if (records.size() != 1) {
            throw new TestFactoryException('getSingleRecord() requires exactly one built record.');
        }

        return records[0];
    }

    /* ========================================================= */
    /* PROTECTED HOOKS                                           */
    /* ========================================================= */

    protected virtual void buildContext() {
    }

    protected abstract SObject buildRecord(Integer index);

    /* ========================================================= */
    /* PRIVATE EXCEPTIONS                                        */
    /* ========================================================= */

    private class TestFactoryException extends Exception {
    }
}