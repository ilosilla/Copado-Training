@isTest
private class BatchSAPPlantWarehousesTest {
   
    @isTest
    static void testSubmitInBatch() {
        Test.startTest();
        Id jobId = BatchSAPPlantWarehouses.submitInBatch();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'A queueable job id should be returned');
    }
   
}