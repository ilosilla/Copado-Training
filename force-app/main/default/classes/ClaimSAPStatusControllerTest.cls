@isTest public with sharing class ClaimSAPStatusControllerTest {

    @TestSetup static void makeData(){
        Order o = DataFactoryOrder.createOrdersForSAP(1)[0];
        OrdersService.activateOrders(new Set<Id>{o.Id});        
    }

    @isTest static void test001() {
        Order o = [select Id, Status from Order limit 1];
        Test.startTest();
        ClaimSAPStatusController.OrderStatusDTO dto = ClaimSAPStatusController.getOrderStatus(o.Id);
        Test.stopTest();
        Assert.areEqual(o.Id, dto.orderId, 'Ids should be the same');
    }
}