/**
* @author 		Ramón Prades
*/
@isTest public class MasterProductSyncReporterTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryProduct.createProducts();
    }

    @isTest private static void test01() {
        Boolean exc = false;
        try {
            MasterProductSyncReporter reporter = new MasterProductSyncReporter();
            reporter.sendReport();
        } catch (Exception ex) {
            exc = true;
        }
        System.assertEquals(false, exc, 'No exception should have occured');
    }
    
} // class