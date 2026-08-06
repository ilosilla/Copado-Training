@isTest global with sharing class MasterProductBackofficeSyncTest {

    @isTest private static void test1() {
        T023T__x[] data = getTestData();
        MasterProductBackofficeSync syncer = new MasterProductBackofficeSync();
        syncer.setTestData(data);
        Integer nrecords = syncer.sync();
        Assert.areEqual(1, nrecords);
    }

    private static List<T023T__x> getTestData() {
        return (T023T__x[])json.deserialize('[{"Matkl__c": "TD001", "Wgbez60__c": "Test Data 1", "Spras__c": "EN"}]',List<T023T__x>.class);
    }
}