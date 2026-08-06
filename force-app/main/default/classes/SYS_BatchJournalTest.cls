@isTest public class SYS_BatchJournalTest {

    @isTest static void test001() {
        BatchMaterialBankImporter importer = new  BatchMaterialBankImporter();
        SYS_BatchJournal batch = new SYS_BatchJournal(importer);
        Assert.areEqual('BatchMaterialBankImporter', batch.journal.JobName__c, 'Wrong Job Name');
        Test.startTest();
        batch.start();
        batch.end(true, 'test');
        Test.stopTest();
        SYS_BatchJournal__c[] records = [select Name from SYS_BatchJournal__c];
        Assert.isTrue(records.size() == 1, 'There should be one record');
    }
}