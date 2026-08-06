/**
 * This is a dummy class to test someof the methods in the abstract class SAPAbstract
 */
@isTest public with sharing class SAPAbstractAPIHandlerTest {

    @isTest private static void test001() {
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        handler.processSkipped(null, 'xxx');
        //handler.parseErrors(null, 'details');
        String rt = handler.getRequestType();
        Assert.areEqual('SAP', rt, 'Request type should be SAP.');
    }

    @isTest private static void test002() {
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        Assert.isTrue(handler.getTimeout() >= 0, 'Timeout should be non-negative');
        try {
            handler.buildSimplePayload();
            Assert.fail('buildSimplePayload should throw an exception');
        } catch (Exception e) {
            Assert.isNotNull(e, 'Exception expected');            
        }
    }

}