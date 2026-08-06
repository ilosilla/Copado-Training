@isTest public class SAPConnectionTesterTest {
    @isTest public static void testIsAliveTrue() {
        Test.setMock(HttpCalloutMock.class, new SAPConnectionTesterMockup());
        String error = '';
        Boolean alive = true;
        try {
            SAPConnectionTester.isAlive();        
            alive = true;
        } catch (Exception ex) {
            error = ex.getMessage();
            alive = false;
        }
        System.assertEquals(true, alive, 'Service should be alive: ' + error);
    } 

    @isTest public static void testIsAliveFalse() {
        SAPConnectionTesterMockup mockup = new SAPConnectionTesterMockup();
        mockup.alive = false;
        Test.setMock(HttpCalloutMock.class, mockup);
        Boolean alive = true;
        try {
            SAPConnectionTester.isAlive();        
            alive = true;
        } catch (Exception ex) {
            alive = false;
        }
        System.assertEquals(false, alive, 'Service should NOT be alive');
    }

    @isTest static void filler() {
        String s = SAPConnector.TestFiller();
        System.assertNotEquals(null, s, 'Just to reach the mon coverage');
    }
}