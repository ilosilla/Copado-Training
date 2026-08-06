@isTest public without sharing class SFOrderReaderTest {

    @testSetup static void setupTestData() {
        DataFactoryOrder.createOrders(1);
    }

    @isTest private static void test001() {
        Order o = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        Id orderId = o.Id;
        B2BSalesDocContracts.OrderHeaderDTO dto = SFOrderReader.readOrder(orderId);
        Assert.isNotNull(dto, 'Expected non-null DTO');
        Assert.areEqual(orderId, dto.orderId, 'The orderId should match');
        Assert.areEqual(o.OrderNumber, dto.orderNumber, 'The order number should match');   
        Assert.isTrue(dto.items.size() > 0, 'Expected at least one line item');
    }
}