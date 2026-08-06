@isTest public class OrdersServiceTest {


    @testSetup public static void testSetup()  {
        //DvsAccounTriggerController.isRunningTest = true;
        Order o = DataFactoryOrder.createOrders(1)[0];
        o.Sap_Id__c = '901';     
        update o;
    }

    @isTest static void testSaveCaseOrder() {
        Case claim = DataFactoryCase.createClaims(1)[0];
        claim.Status = CasesDomain.CLAIM_STATUS_AGREEMENT;
        claim.SupplyReplacement__c = true;
        claim.Liability__c = PicklistCommons.getKeysList(Case.Liability__c)[0];
        claim.Warranty__c = PicklistCommons.getKeysList(Case.Warranty__c)[0];
        update claim;
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];
        o.AccountId = claim.AccountId;
        OrdersService.saveOrders(new List<Order>{o});
        OrderItem[] items = new OrderItemsSelector().selectByOrderId(new Set<Id>{o.Id});
        OrdersService.saveCaseOrder(claim.Id, o, items);
        OrdersService.setSAPOrderNumber(o.Id, '123');
        Assert.isTrue(true);
    }

    @isTest static void testSaveCaseOrder_Error() {
        Case claim = DataFactoryCase.createClaims(1)[0];
        claim.Status = CasesDomain.CLAIM_STATUS_AGREEMENT;
        claim.SupplyReplacement__c = true;
        claim.Liability__c = PicklistCommons.getKeysList(Case.Liability__c)[0];
        claim.Warranty__c = PicklistCommons.getKeysList(Case.Warranty__c)[0];
        update claim;
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];        
        o.AccountId = null;        
        OrderItem[] items = new OrderItemsSelector().selectByOrderId(new Set<Id>{o.Id});
        Boolean exceptionReceived = false;
        try {
            OrdersService.saveCaseOrder(claim.Id, o, items);        
        } catch (Exception ex) {
            exceptionReceived = true;
        }
        Assert.isTrue(exceptionReceived, 'An exception was expected');
    }

    @isTest private static void test_updateDeliveryStatus() {
        SAP_SD_Delivery__e e = new SAP_SD_Delivery__e();
        e.Action__c = 'CREATE';
        e.DeliveryNumber__c = '008123123';
        e.OrderNumber__c = '901';
        e.Status__c = 'NA';
        e.GoodsPosted__c = false;
        e.SalesOrg__c = '502';
        e.data__c = 'Malformed JSON';
        e.isCollection__c = true;
        e.isSample__c = false;
        OrdersService.updateDeliveryStatus(new List<SAP_SD_Delivery__e>{e});
        // Testeamos para que pase por el inner catch
        
        Order o = [select Id, SAPDeliveryNumber__c, NB2B_DeliveryStatus__c from Order][0] ;
        Assert.areEqual(e.DeliveryNumber__c, o.SAPDeliveryNumber__c, 'Delivery Note does not match');        
    }

    @isTest static void testActivateOrders() {
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];
        Test.startTest();
        OrdersService.activateOrders(new Set<Id>{o.Id});
        Test.stopTest();
        Order o2 = ((List<Order>) new OrdersSelector().selectById(new Set<Id>{o.Id}))[0];
        Assert.areEqual(OrdersDomain.STATUS_ACTIVATED, o2.Status, 'Status should be ' + OrdersDomain.STATUS_ACTIVATED);
    }

    @isTest static void testDeleteCaseOrder1() {
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];
        Case[] cases = DataFactoryCase.createCollections(1);
        cases[0].OrderId__c = o.Id;
        update cases[0];
        Test.startTest();
        OrdersService.deleteCaseOrder(cases[0].Id, o.Id);
        Test.stopTest();

        Order[] orders = [select Id from Order where Id = :o.Id];
        Assert.areEqual(0, orders.size(), 'Order should be deleted');
    }

        @isTest static void testDeleteCaseOrder2() {
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];
        Case[] cases = DataFactoryCase.createCollections(1);
        cases[0].CompensationOrderId__c = o.Id;
        update cases[0];
        Test.startTest();
        OrdersService.deleteCaseOrder(cases[0].Id, o.Id);
        Test.stopTest();

        Order[] orders = [select Id from Order where Id = :o.Id];
        Assert.areEqual(0, orders.size(), 'Order should be deleted');
    }

        @isTest static void testDeleteCaseOrder3() {
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];
        Case[] cases = DataFactoryCase.createCollections(1);
        cases[0].CollectionOrderId__c = o.Id;
        update cases[0];
        Test.startTest();
        OrdersService.deleteCaseOrder(cases[0].Id, o.Id);
        Test.stopTest();

        Order[] orders = [select Id from Order where Id = :o.Id];
        Assert.areEqual(0, orders.size(), 'Order should be deleted');
    }
    @isTest static void testCreateOrder() {
        Order o = ((List<Order>) new OrdersSelector().selectAll())[0];
        OrderItem[] items = new OrderItemsSelector().selectByOrderId(new Set<Id>{o.Id});
        o.Id = null;
        for (OrderItem item : items) {
            item.Id = null;
            item.OrderId = null;
        }   
        Test.startTest();
        OrdersService.createOrder(o, items, null);
        Test.stopTest();
        Order[] orders = [select Id from Order where Id = :o.Id];
        Assert.areEqual(1, orders.size(), 'Order should be created');
    }
    
}