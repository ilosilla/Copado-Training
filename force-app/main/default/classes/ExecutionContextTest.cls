@isTest
private class ExecutionContextTest {
    @isTest static void testGetUserExecutionTest() {
        ExecutionContext context = ExecutionContext.getUserExecutionContext( );
        
        // Test there's a default execution context (by being not null)
        System.assertNotEquals(context, null);            
    }
}