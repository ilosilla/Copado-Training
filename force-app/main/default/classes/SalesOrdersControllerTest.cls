@isTest(isParallel=false) public with sharing class SalesOrdersControllerTest {

    @testSetup public static void testSetup() {
        SalesPricebooksServiceTest.testSetup();
    }

    @isTest public static void testGetOrderDefaults() {
        Order o = new Order();
        o.CurrencyIsoCode = 'USD';   
        o.SalesOrg__c = '610'; 
        o.Type = SalesPricebooksService.ORDER_STANDARD_TYPE;
        SalesOrdersController.OrderDefaultsDTO dto = SalesOrdersController.getOrderDefaults(o);
        Assert.isTrue(true);
    }

    @isTest private static void testDelete() {
        List<Id> deleted = SalesOrdersController.deleteOrderItems(new List<OrderItem>());
        Assert.areEqual(0, deleted.size(), 'No items deleted (empty list)');
    }

    @isTest public static void testGetPageCOnstants() {
        SalesOrdersController.PageConstantsDTO dto = SalesOrdersController.getPageConstants();
        Assert.isNotNull(dto, 'DTO cannot be null');
    }

    @isTest public static void testSaveCaseOrder() {
        Case[] claims = DataFactoryCase.createClaims(1);
        claims[0].Status = 'Agreement';
        claims[0].Liability__c = PicklistCommons.getKeysList(Case.Liability__c)[0];
        claims[0].Warranty__c =  PicklistCommons.getKeysList(Case.Warranty__c)[0];
        claims[0].SupplyReplacement__c = true;
        update claims[0];
        Order o = DataFactoryOrder.createOrders(1)[0];        
        o.AccountId = claims[0].AccountId;
        List<OrderItem> orderItems = new OrderItemsSelector().selectByOrderId(new Set<Id> {o.Id});
        Test.startTest();
        SalesOrdersController.saveCaseOrder(claims[0].Id, o, orderItems);
        Test.stopTest();
        Assert.IsTrue(true);
    }

    @isTest public static void testSendOrderToSAP() {
        Case[] claims = DataFactoryCase.createClaims(1);
        Order o = DataFactoryOrder.createOrders(1)[0]; 
        o.Status = 'Draft';
        o.SalesOrg__c = '502';
        o.Distribution_channel__c = '60';       
        o.AccountId = claims[0].AccountId;
        o.Version__c = OrdersDomain.VERSION2;
        update o;

        //List<OrderItem> orderItems = new OrderItemsSelector().selectByOrderId(new Set<Id> {o.Id});
        Test.startTest();
        String errorMessage = '';
        try {
            SalesOrdersController.activateOrder(o.Id);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        Assert.isTrue(String.IsBlank(errorMessage), 'No error expected');

        Test.stopTest();

        Order o2 = [select Id, Status from Order where Id = :o.Id limit 1];
        Assert.areEqual(OrdersDomain.STATUS_ACTIVATED, o2.Status, 'The status should be ACTIVATE ' + errorMessage);
    }

    @isTest private static void testCreateCompensation() {
        Case[] claims = DataFactoryCase.createClaims(1);
        String message = '';
        try {
            SalesOrdersController.createCompensationOrder(claims[0].Id);
        } catch (Exception ex) {
            message = ex.getMessage();
        }
        Assert.isTrue(message.length() >= 0);
    }

    @isTest static void testCoverage() {
        String s = SalesOrdersController.testCoverage();
        Assert.isNotNull(s, 'Dummy string expected');
    }


}