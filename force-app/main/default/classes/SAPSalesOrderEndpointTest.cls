@isTest public with sharing class SAPSalesOrderEndpointTest {
    @TestSetup static void makeData(){
        DataFactoryOrder.createOrders(1);
    }

    @isTest private static void testEndpoint() {
        // Retrieve 5 orders
        List<Order> allOrders = [select Id, Status from Order];

        Test.startTest();
        Set<Id> orderIds = TypeConversionCommons.listToSet(allOrders);
        SAPSalesOrderEndpoint endpoint = new SAPSalesOrderEndpoint(orderIds);
        Integer numRequests = endpoint.doRequests();
        Test.stopTest();
        
        Assert.areEqual(orderIds.size(), numRequests, 'Method should have returned ' + orderIds.size() + ' new requests');        
        List<SAPRequestQueue__c> queued = getSAPRequests();
        Assert.areEqual(numRequests, queued.size(), 'There should be ' + numRequests + ' in the SAP queue');
    
    }

    private static List<SAPRequestQueue__c> getSAPRequests() {
        return [select Id, Name, SAPEndpoint__c from SAPRequestQueue__c];
    }


}