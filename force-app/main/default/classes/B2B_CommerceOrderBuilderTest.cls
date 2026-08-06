@isTest
public class B2B_CommerceOrderBuilderTest {

    private static BuilderTestContext buildTestBuilder() {
        DataFactoryEcommerce factory = new DataFactoryEcommerce();
        factory.buildEcommerce();
        WebCart cart = factory.createCart();
        B2B_CommerceCartAdapter.CommerceCartData cartData = B2B_CommerceCartAdapter.getCartData(factory.StoreId, cart.Id);

        Product2[] fl = [select Id from Product2 where StockKeepingUnit = 'CC_FEE'];
        if (fl.size() == 0) {
            Product2 fee = new Product2(Name = 'CC_FEE', StockKeepingUnit = 'CC_FEE', IsActive = true, SAPMake__c = '-', Umv__c = 'UN');
            insert fee;
        }

        BuilderTestContext context = new BuilderTestContext();
        context.cartId = cart.Id;
        context.accountId = cart.AccountId;
        context.builder = new B2B_CommerceOrderBuilder(cartData.cart, cartData.cartItems)
            .withPaymentModel('PREPAID')
            .withPoNumber('PO123')
            .withCreditCardSurcharge(10)
            .withCreditCardSurchargePct(2.5);
        return context;
    }

    @isTest(SeeAllData=true) private static void test() {
        BuilderTestContext context = buildTestBuilder();
        B2B_CommerceOrderBuilder builder = context.builder;

        Test.startTest();
        builder.build().save();
        builder.createSummary();
        Test.stopTest();
        Order o = builder.getOrder();
        OrderItem[] oitems = builder.getOrderItems();        
        OrderDeliveryGroup odg = builder.getOrderDeliveryGroup();
        ConnectApi.OrderSummaryOutputRepresentation orderSummary = builder.getOrderSummaryOutput();
        
        Assert.isNotNull(o, 'Order should be created');        
        Assert.isNotNull(orderSummary, 'Order Summary should be created');        
        Assert.isTrue(oitems.size() > 0, 'Order Items should be created');
        Assert.isNotNull(odg, 'Order Delivery Group should be created');
    }

    @isTest(SeeAllData=true)
    private static void testSave_buildsOrderWhenCalledDirectly() {
        BuilderTestContext context = buildTestBuilder();
        B2B_CommerceOrderBuilder builder = context.builder;

        Test.startTest();
        builder.save();
        Test.stopTest();

        Assert.isNotNull(builder.getOrder(), 'save() should build the order when it has not been built yet.');
        Assert.isTrue(builder.getOrderItems().size() > 0, 'save() should also populate the order items when it builds implicitly.');
        Assert.isNotNull(builder.getOrderDeliveryGroup(), 'save() should also populate the order delivery group when it builds implicitly.');
    }

    @isTest(SeeAllData=true)
    private static void testCreateSummary_throwsWhenOrderHasNotBeenSaved() {
        BuilderTestContext context = buildTestBuilder();
        B2B_CommerceOrderBuilder builder = context.builder;

        try {
            builder.createSummary();
            Assert.fail('createSummary() should fail when the order has not been saved yet.');
        } catch (ContextException ex) {
            Assert.isNotNull(ex, 'A ContextException should be raised when createSummary() is called before saving the order.');
        }
    }

    @isTest(SeeAllData=true)
    private static void testSave_updatesPendingPaymentAndDeliveryRequirement() {
        BuilderTestContext context = buildTestBuilder();

        PaymentRequest__c paymentRequest = new PaymentRequest__c(
            RetryCount__c = 0,
            Token__c = B2B_PaymentsService.generatePaymentToken(),
            CartId__c = context.cartId,
            Account__c = context.accountId,
            Amount__c = 100,
            CurrencyIsoCode = 'USD',
            PONumber__c = 'PO9999',
            PaymentGateway__c = 'PORSA_GATEWAY',
            StartedAt__c = System.now(),
            Status__c = B2B_PaymentsService.WAITING_PAYMENT_STATUS,
            Type__c = 'PAYMENT',
            User__c = UserInfo.getUserId()
        );
        insert paymentRequest;

        CartDeliveryGroup cdg = [
            SELECT Id, ContactPointAddressId__c
            FROM CartDeliveryGroup
            WHERE CartId = :context.cartId
            LIMIT 1
        ];
        DeliveryRequirement__c deliveryRequirement = new DeliveryRequirement__c(
            Cart__c = context.cartId,
            ContactPointAddress__c = cdg.ContactPointAddressId__c,
            LiftgateRequired__c = true
        );
        insert deliveryRequirement;

        Test.startTest();
        context.builder.save();
        Test.stopTest();

        Order orderRecord = context.builder.getOrder();
        PaymentRequest__c refreshedPayment = [
            SELECT Id, Order__c, Status__c
            FROM PaymentRequest__c
            WHERE Id = :paymentRequest.Id
            LIMIT 1
        ];
        DeliveryRequirement__c refreshedRequirement = [
            SELECT Id, Order__c
            FROM DeliveryRequirement__c
            WHERE Id = :deliveryRequirement.Id
            LIMIT 1
        ];

        Assert.areEqual(orderRecord.Id, refreshedPayment.Order__c, 'Pending payment requests should be linked to the created order.');
        Assert.areEqual(B2B_PaymentsService.COMPLETED_STATUS, refreshedPayment.Status__c, 'Pending payment requests should be marked as completed after save().');
        Assert.areEqual(orderRecord.Id, refreshedRequirement.Order__c, 'Pending delivery requirements should be linked to the created order.');
    }

    private class BuilderTestContext {
        private B2B_CommerceOrderBuilder builder;
        private Id cartId;
        private Id accountId;
    }
}