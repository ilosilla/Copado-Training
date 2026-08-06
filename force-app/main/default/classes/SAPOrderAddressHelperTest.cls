@isTest public class SAPOrderAddressHelperTest {

    @isTest private static void test001() {
        Order[] orders = makeData();
        SAPOrderAddressHelper helper = new SAPOrderAddressHelper(orders);
        helper.matchSAPId();
        Map<Id, OrderDeliveryGroup> results = helper.getDeliveryAddressesMap();
        Assert.areEqual(3, results.keySet().size(), '3 records expected');

        // The first one should have the account sap id
        OrderDeliveryGroup odg0 = results.get(orders[0].Id);
        Assert.areEqual('1', odg0.SAPId__c, 'SAPId *1* expected');

        // El second one the address sap id
        OrderDeliveryGroup odg1 = results.get(orders[1].Id);
        Assert.areEqual('5', odg1.SAPId__c, 'SAPId *5* expected');
        

        // And te third one should be empty
        OrderDeliveryGroup odg2 = results.get(orders[2].Id);
        Assert.isNull(odg2.SAPId__c, 'Null expected');        
    }
    
    private static List<Order> makeData() {
        DataFactoryAccount.autoInsert = false;
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        acc.BillingCity = 'Ramsey';
        acc.BillingCountryCode = 'US';
        acc.BillingStateCode = 'NJ';
        acc.BillingStreet = '65 Route 17';
        acc.BillingPostalCode = '07047';
        acc.SAP_Id__c = '1';
        insert acc;

        DataFactoryContactPointAddresses.autoInsert  = false;
        ContactPointAddress cpa = DataFactoryContactPointAddresses.createAccountAddresses(acc.Id, 1)[0];
        cpa.City = 'Paramus';
        cpa.CountryCode = 'US';
        cpa.StateCode = 'NJ';
        cpa.Street = '14 Route 17';
        cpa.PostalCode = '07005';
        cpa.SAPId__c = '5';
        insert cpa;

        DataFactoryOrder.useContactPointAddresses = false;
        Order[] orders = DataFactoryOrder.createOrders(acc.Id, 3);

        OrderDeliveryGroup[] deliveries = new List<OrderDeliveryGroup>();

        // The first order delivers to the account address
        OrderDeliveryGroup delivery1 = new OrderDeliveryGroup(
            OrderId = orders[0].Id,                
            DeliverToCountryCode = acc.BillingCountryCode,
            DeliverToPostalCode = acc.BillingPostalCode,
            DeliverToCity = acc.BillingCity,
            DeliverToStreet = acc.BillingStreet,
            DeliverToName = acc.Name,
            DeliverToState = acc.BillingState,
            DeliverToStateCode = acc.BillingStateCode
        );
        deliveries.add(delivery1);

        // The second delivers to the contact point
        OrderDeliveryGroup delivery2 = new OrderDeliveryGroup(
            OrderId = orders[1].Id,                
            DeliverToCountryCode = cpa.CountryCode,
            DeliverToPostalCode = cpa.PostalCode,
            DeliverToCity = cpa.City,
            DeliverToStreet = cpa.Street,
            DeliverToName = cpa.Name,
            DeliverToState = cpa.State,
            DeliverToStateCode = cpa.StateCode
        );
        deliveries.add(delivery2);

        // The thirsd delivers to a new address
        OrderDeliveryGroup delivery3 = new OrderDeliveryGroup(
            OrderId = orders[2].Id,                
            DeliverToCountryCode = 'US',
            DeliverToPostalCode = '47752-0185',
            DeliverToCity = 'Springfield',
            DeliverToStreet = '17 Terrace Green',
            DeliverToName = 'Simpsons Family',
            DeliverToStateCode = 'NC'
        );
        deliveries.add(delivery3);

        insert deliveries;

        return orders;

    }

    private static OrderDeliveryGroup readOrderDelivery(Id orderId) {
        return [select Id, OrderId, DeliverToStreet, DeliverToCity, DeliverToStateCode, DeliverToCountryCode, DeliverToPostalCode from OrderDeliveryGroup where OrderId = :orderId limit 1];
    }

}