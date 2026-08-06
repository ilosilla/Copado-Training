@isTest public class DataFactoryOrderTest {

    static Integer numOrders = 10;
    static Boolean forSAP = false;

    @testSetup
    static void testCreateOrders() {
        if (forSAP) {
            DataFactoryOrder.createOrdersForSAP(numOrders);
        } else {
            DataFactoryOrder.createOrders(numOrders);
        }
    }

    @isTest private static void test001() {
        forSAP = false;
        List<Order> orders = [SELECT Id, Status FROM Order];
        Assert.areEqual(numOrders, orders.size(), 'There should be ' + numOrders + ' orders');
    }

    @isTest private static void test001A() {        
        forSAP = true;
        List<Order> orders = [SELECT Id, Status FROM Order];
        Assert.areEqual(numOrders, orders.size(), 'There should be ' + numOrders + ' orders');
    }


    @isTest private static void test002() {
        forSAP = false;
        List<OrderDeliveryGroup> groups = [SELECT Id FROM OrderDeliveryGroup];
        Assert.areEqual(numOrders, groups.size(), 'There should be ' + numOrders + ' delivery groups');        
    }
}