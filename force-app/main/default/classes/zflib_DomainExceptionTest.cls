@IsTest
private class zflib_DomainExceptionTest {    
    @IsTest 
    private static void testDomainException() {
        try {
            zflib_DomainExceptionTest.forceException();
            System.AssertEquals('Testing', 'np', 'It should not be here');
        } catch (zflib_DomainException zex) {
            System.AssertEquals('Testing', zex.getMessage());
        }
    }

    private static void forceException() {
        throw new zflib_DomainException('Testing');
    }
}