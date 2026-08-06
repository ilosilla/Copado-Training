@isTest public with sharing class SYS_ProcessReceiptsTest {

    @testSetup static void testSetup() {
        SYS_ProcessReceipt__c r = new SYS_ProcessReceipt__c();
        r.Namespace__c = 'MATERIAL-BANK';
        R.DedupKey__c = 'File1.TXT';
        insert r;
    }

    @isTest static void test001() {
        SYS_ProcessReceipt__c sample = [select Key__c from SYS_ProcessReceipt__c limit 1];
        Assert.areEqual('MATERIAL-BANK-FILE1.TXT', sample.Key__c);
        SYS_ProcessReceipt__c[] receipts = new SYS_ProcessReceiptsSelector().selectByKey(new Set<String>{sample.Key__c});
        Assert.areEqual(sample.Key__c, receipts[0].Key__c, 'Keys should be the same');
    }
}