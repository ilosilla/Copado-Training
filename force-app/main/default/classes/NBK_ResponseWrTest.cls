@isTest
private class NBK_ResponseWrTest {
    @isTest
    static void testConstructorWithSuccessAndError() {
        CustomException testError = new CustomException('Test error message');
        NBK_ResponseWr response = new NBK_ResponseWr(true, testError, null, false, 5);
        System.assertEquals(true, response.getSuccess());
        System.assertEquals('Test error message', response.getErrorMsg());
        System.assertEquals(null, response.getDataJSON());
    }
    @isTest
    static void testConstructorWithSuccessAndData() {
        NBK_ResponseWr response = new NBK_ResponseWr(true, null, 'Test JSON data');
        System.assertEquals(true, response.getSuccess());
        System.assertEquals(null, response.getErrorMsg());
        System.assertEquals('Test JSON data', response.getDataJSON());
    }
    @isTest
    static void testConstructorWithErrorMessage() {
        NBK_ResponseWr response = new NBK_ResponseWr('Test error message');
        System.assertEquals(false, response.getSuccess());
        System.assertEquals('Test error message', response.getErrorMsg());
        System.assertEquals(null, response.getDataJSON());
    }
    @isTest
    static void testSetValidationMsg() {
        NBK_ResponseWr response = new NBK_ResponseWr();
        response.setValidationMsg('Validation message');
    }

    private class CustomException extends Exception {}
}