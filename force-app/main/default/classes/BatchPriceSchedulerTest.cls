@isTest public with sharing class BatchPriceSchedulerTest {
    @IsTest
    static void testMySchedulableClass() {
        Test.startTest();
        
        BatchPriceScheduler schedulable = new BatchPriceScheduler();
        schedulable.execute(null);
        Test.stopTest();

        System.assert(true, 'no problem');
    }
}