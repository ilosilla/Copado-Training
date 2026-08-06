// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// USE OrdersServiceTest and SAPOrdersServiceTest TO REACH THE NECESSARY 80%
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
@isTest public class OrdersDomainTest {

    @testSetup private static void testSetup() {
        DataFactoryOrganization.createData();
        DataFactoryOrder.createOrders(2);
    }

    @isTest private static void test001() {
        Test.startTest();
        OrdersSelector selector = new OrdersSelector();
        List<Order> orders = (List<Order>) selector.selectAll();
        orders[0].SAPDeliveryNumber__c = '008001';
        orders[0].SAPGoodsPosted__c = false;
        orders[0].EffectiveDate = null;
        orders[0].Status = null;
        orders[1].SAPDeliveryNumber__c = '008001';
        orders[1].SAPGoodsPosted__c = true;

        update orders;
        Test.stopTest();

        Order o0 = (Order) selector.selectSingle(orders[0].Id);
        Assert.areEqual(OrdersDomain.DELIVERY_DELIVERING, o0.NB2B_DeliveryStatus__c, 'Status not correct');
        Assert.isNotNull(o0.EffectiveDate, 'An effective date should have been set');

        Order o1 = (Order) selector.selectSingle(orders[1].Id);
        Assert.areEqual(OrdersDomain.DELIVERY_DELIVERED, o1.NB2B_DeliveryStatus__c, 'Status not correct');

        delete o1;
        Order[] deletedOrders = [SELECT Id FROM Order WHERE Id = :o1.Id];
        Assert.areEqual(0, deletedOrders.size(), 'The order should have been deleted');
    }
    
}