@isTest public with sharing class SAPSalesOrderMapperTest {

    @TestSetup
    static void makeData(){
        DataFactoryOrder.createOrders(1);
    }

    @isTest static void testMapping() {
        Order o = (Order) new OrdersSelector().selectAll().get(0);
        OrderItem[] items = new OrderItemsSelector().selectByOrderId(new Set<Id>{o.Id});        
        OrderDeliveryGroup odg = [select Id, DeliveryInstructions, SAPId__c, DesiredDeliveryDate 
            from OrderDeliveryGroup where OrderId = :o.Id limit 1];

        o.Type = 'ZW04';
        SAPSalesOrderMapper mapper = new SAPSalesOrderMapper(o, odg, items)
            .withoutPrices()        
            .withConfirmationEmail('test@example.com')
            .withRequestedBy('100001');
        SAPOrderHeaderDTO dto = mapper.transform();

        Assert.isNotNull(dto);
    }   
}