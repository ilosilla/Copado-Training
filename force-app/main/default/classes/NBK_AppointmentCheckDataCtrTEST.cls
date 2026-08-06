@isTest
private class NBK_AppointmentCheckDataCtrTEST {

    @isTest
    static void testRegisterError() {
        // Simulate input data
        String errorMessage = 'Test error message';
        
        // Call the method to be tested
        Test.startTest();
        NBK_AppointmentCheckDataCtr.registerError(errorMessage);
        Test.stopTest();
        
        // Validate the expected behavior (assertions)
        // Check if the logs or other expected outcomes are correctly handled
        System.assert(true, 'Add your assertions here');
    }
}