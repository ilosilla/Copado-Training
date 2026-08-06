@isTest public with sharing class OrderItemsSelectorTest {

    @TestSetup static void makeData(){
        DataFactoryOrder.createOrders(10);
    }

    @isTest static void test001() {
        Order[] orders = [select Id, SAP_Id__c from Order];
        Set<Id> orderIds = TypeConversionCommons.listToSet(orders);
        List<OrderItem> orderItems = new OrderItemsSelector().selectByOrderId(orderIds);
        Assert.isTrue(orderItems.size()>0, 'There should be some orderItems');
    }

}