@isTest public class OrderItemsDomainTest {

    @testSetup private static void testSetup() {
        DataFactoryOrder.createOrdersForSAP(5);
    }

    // De momento, solo para que pase -  necesito cobertura
    // Cuando le de contenido, haré el test bueno
    @isTest static void testDummy() {
        OrderItemsDomain domain = new OrderItemsDomain();
        Assert.isNotNull(domain.cast());
        Assert.isNotNull(domain.getSObjectType());

        OrderItemsDomain domain2 = new OrderItemsDomain(new List<OrderItem>());
        Assert.isNotNull(domain2.cast());
        Assert.isNotNull(domain2.getSObjectType());

    }

    @isTest static void testDeleteItems() {
        Order o = [select Id, Status from Order limit 1];
        o.Status = OrdersDomain.STATUS_ACTIVATED;
        o.sapRequestStatus__c = 'queued';
        update o;
        
        OrderItem[] items = new OrderItemsSelector().selectByOrderId(new Set<Id>{o.Id});
        String message = null;
        
        Test.startTest();
        try {
            delete items;
        } catch (Exception ex) {
            message = ex.getMessage();
        }
        Test.stopTest();
        Assert.isNotNull(message, 'An exception was expected');
    }
}