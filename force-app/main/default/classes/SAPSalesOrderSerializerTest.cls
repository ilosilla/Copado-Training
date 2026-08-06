@isTest public with sharing class SAPSalesOrderSerializerTest {

    @TestSetup static void makeData(){        
        Order[] orders = DataFactoryOrder.createOrders(5);
        for (Order o : orders) {
            o.Type = 'Z051';
        }
        update orders;
    }

    @isTest static void testSerialize() {
        Order[] orders = [select Id from Order];
        Set<Id> orderIds = TypeConversionCommons.listToSet(orders);
        Assert.areEqual(orders.size(), orderIds.size(), 'Set not generated correctly');

        SAPSalesOrderSerializer serializer = new SAPSalesOrderSerializer();
        String json = serializer.serialize(orderIds);
        List<Object> objects = serializer.getSerializedObjects();
        Assert.isTrue(objects.size() > 0, 'No read objects??');
        Assert.isNotNull(json, 'No json returned by the serializer');
    }

}