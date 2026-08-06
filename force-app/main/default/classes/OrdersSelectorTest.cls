@isTest public class OrdersSelectorTest {
    @testSetup private static void testSetuo() {
        DataFactoryOrder.createOrders(10);
    }

    @isTest static void test001() {
        Order o = [select Id, SAP_Id__c from Order limit 1];
        o.Sap_Id__c = '000123';
        update o;
        List<Order> orders = new OrdersSelector().selectBySAPOrder(new Set<String>{ o.SAP_Id__c });
        Assert.areEqual(1, orders.size(), 'There should be 1 order and only 1');
    }
    
}