@isTest public with sharing class OrderItemsServiceTest {
    
    @testSetup private static void testSetup() {
        DataFactoryOrder.createOrdersForSAP(5);
    }

    @isTest static void testDeleteItems() {    
        Order o = [select Id, Status from Order limit 1];            
        OrderItem[] items = new OrderItemsSelector().selectByOrderId(new Set<Id>{o.Id});
        Test.startTest();
        OrderItem[] deleted = OrderItemsService.deleteItems(items);
        Test.stopTest();
        Assert.isTrue(deleted.size() > 0, 'The items should have been deleted');
    }
}