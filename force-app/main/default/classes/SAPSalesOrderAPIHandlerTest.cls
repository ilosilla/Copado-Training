@isTest public with sharing class SAPSalesOrderAPIHandlerTest {

    static String responseOK = '[{"DELIVERY": "","INDEX": 1,"NUMBER": "0011001879","RESTOCKINGCHARGES": 0,"SOURCEORDERID": "123321","SUCCESS": true}]';
    static String responseERR = '[{"ERROR": {"ID": "016","TYPE": "E","MESSAGE": "&Referred invoice is from another customer&."},"INDEX": 1,"SOURCEORDERID": "123321","SUCCESS": false}]'; // Error JSON
    static Id orderId;

    @testSetup static void makeData(){        
       DataFactoryOrder.createOrdersForSAP(1);
    }

    @isTest private static void testSetSAPRequest() {
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        handler.setSAPRequestItem(null);
        Assert.isNotNull(handler);
    }
    
    @isTest private static void testGetServiceName() {
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        Assert.isNotNull(handler.getServiceName());
    }

    @isTest private static void testPrepareBody() {
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        Assert.isNotNull(handler.getPayload());
    }

    @isTest private static void testGetMethod() {
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        Assert.isNotNull(handler.getHttpMethod('CREATE'));
        Assert.isNotNull(handler.getHttpMethod('UPDATE'));
        Assert.isNotNull(handler.getHttpMethod('DELETE'));
        Assert.isNotNull(handler.getHttpMethod('READ'));         
    }

    @isTest private static void parseErrors() {
        Order o = [select Id from Order limit 1];
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        String message = handler.parseErrors(o.Id, responseERR);
        Assert.isNotNull(message, 'A message error is expected');
    }

    @isTest private static void processResponse() {      
        Order o = [select Id from Order limit 1];  
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        String orderNumber = handler.processResponse(o.Id, 200, responseOK);
        Assert.areEqual('0011001879', orderNumber, 'Expected order number 0011001879');
    }

    @isTest private static void processError() {
        Order o = [select Id from Order limit 1];  
        SAPSalesOrderAPIHandler handler = new SAPSalesOrderAPIHandler();
        handler.processError(o.Id, 404, 'message', 'details');
        Assert.isNotNull(o.Id);
    }

}