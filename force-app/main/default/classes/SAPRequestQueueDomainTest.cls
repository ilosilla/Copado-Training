@isTest public class SAPRequestQueueDomainTest {

    @TestSetup static void makeData(){
        SystemSettings__c settings = SystemSettings.getSystemSettings();
        settings.SAPDispatcherEnabled__c = false;
        upsert settings;
    }

    // Test happy path
    @isTest private static void testOnApplyDefaults_1() {
       List<SAPRequestQueue__c> queue = new List<SAPRequestQueue__c>();
       queue.add(getRecord('1', 'CREATE', false));
       queue.add(getRecord('2', 'CREATE', false));
       queue.add(getRecord('3', 'UPDATE', false));
       queue.add(getRecord('4', 'UPDATE', false));
       test.startTest();
       insert queue;
       test.stopTest();

       List<SAPRequestQueue__c> results = [select Id, UniqueKey__c from SAPRequestQueue__c where ActionRequested__c = 'CREATE'];
       Assert.isNotNull(results[0].UniqueKey__c, 'UniqueKey should not be null');

       List<SAPRequestQueue__c> results2 = [select Id, UniqueKey__c from SAPRequestQueue__c where ActionRequested__c != 'CREATE'];
       Assert.isNull(results2[0].UniqueKey__c, 'UniqueKey should be null but is ');

    }

    @isTest private static void testOnApplyDefaults_2() {
        List<SAPRequestQueue__c> queue = new List<SAPRequestQueue__c>();
        queue.add(getRecord('1', 'CREATE', false));
        queue.add(getRecord('1', 'CREATE', false));
        Boolean exceptionThrown = false;
        try {
            insert queue;
        } catch (Exception ex) {
            exceptionThrown = true;
        } 
        Assert.isTrue(exceptionThrown, 'An exception should have been raised if a duplicate creation is detected');
    }

    @isTest private static void testOnApplyDefaults_3() {
        List<SAPRequestQueue__c> queue = new List<SAPRequestQueue__c>();
        queue.add(getRecord('1', 'UPDATE', false));
        queue.add(getRecord('1', 'UPDATE', false));
        Boolean exceptionThrown = false;
        try {
            insert queue;
        } catch (Exception ex) {
            exceptionThrown = true;
        } 
        Assert.isFalse(exceptionThrown, 'An exception should not have been raised if a duplicate update is detected');
    }

    @isTest private static void testOnApplyDefaults_4() {
        List<SAPRequestQueue__c> queue = new List<SAPRequestQueue__c>();
        queue.add(getRecord('1', 'CREATE', true));
        queue.add(getRecord('1', 'CREATE', true));
        Boolean exceptionThrown = false;
        try {
            insert queue;
        } catch (Exception ex) {
            exceptionThrown = true;
        } 
        Assert.isFalse(exceptionThrown, 'An exception should not have been raised if a duplicate update is detected');
    }


 
    private static SAPRequestQueue__c getRecord(String id, String action, Boolean allowDuplicates) {
        SAPRequestQueue__c q = new SAPRequestQueue__c();
        q.ActionRequested__c = action;
        q.RequesterID__c = id;
        q.SAPAPIHandler__c = 'SAPSalesOrderAPIHandler';
        q.SAPEndpoint__c = 'SAPSalesOrderEndpoint';
        q.AllowDuplicates__c = allowDuplicates;
        return q;    
    }
}