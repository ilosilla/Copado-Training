@isTest public class SYS_ProcessReceiptTest {

    @isTest static void test001() {
        String  namespace = 'TEST';
        String dedup = '1000';
        SYS_ProcessReceipt r = new SYS_ProcessReceipt(namespace, dedup);
        Assert.isFalse(r.exists(), 'The receipt should not exist');
        Test.startTest();
        r.save(true, '');
        Test.stopTest();
        Assert.isTrue(r.exists(), 'The receipt should exist now');
    }
}