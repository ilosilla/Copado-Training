/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Data Factories
 * @description    Order
*/
public class DataFactoryOrder {

    public static Boolean useContactPointAddresses = true;
    public static Integer startingNumber = 0;          // To avoid duplicates

    public static List<Order> createOrdersForSAP(Integer numOrders) {
        Id accountId = null;
        List<Order> orders = createOrders(numOrders);
        for (Order order : orders) {
            order.Type = 'Z051';
            order.SalesOrg__c = '502';
            order.Distribution_channel__c = '70';
            order.sapRequestStatus__c = null;
            accountId = order.AccountId;
        }
        update orders;
        Account acc = new Account();        
        acc.Id = accountId;
        acc.SAP_Id__c = '123321';
        update acc;
        return orders;
    }
    
    public static List<Order> createOrders(Integer numOrders) {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        List<Order> orders = createOrders(acc.Id, numOrders);
        return orders;
    }
    
    public static List<Order> createOrders(Id accountId, Integer numOrders) {
        List<Order>orders = new List<Order>();
        for (Integer i = startingNumber; i < startingNumber + numOrders; i++) {
            Order order = new Order(
                Name='Test Order ' + i,
                Status='Draft',
                Type='Standard',
                CurrencyIsoCode = 'USD',
                EffectiveDate = Date.today(),
                AccountId = accountId,
                SalesOrg__c = '502',
                RecordTypeId = RecordTypeLibrary.Order_StandardV1
            );
            orders.add(order);
        }
        insert orders;
        completeOrders(accountId, orders);        
        return orders;
    }

    private static void completeOrders(Id accountId, List<Order>orders) {
        DataFactoryProduct.ignoreStandardPriceBook = true;
        List<Product2> products = DataFactoryProduct.createProducts();
        List<ContactPointAddress> addresses;
        if (useContactPointAddresses) {
            addresses = DataFactoryContactPointAddresses.createAccountAddresses(accountId, orders.size());
        }
        List<OrderItem> items = new List<OrderItem>();
        Integer i = 0;
        for (Order o : orders) {
            if (useContactPointAddresses) {
                OrderDeliveryGroup delivery = new OrderDeliveryGroup(
                    OrderId = o.Id,                
                    DeliverToCountryCode = addresses[i].CountryCode,
                    DeliverToPostalCode = addresses[i].PostalCode,
                    DeliverToCity = addresses[i].City,
                    DeliverToStreet = addresses[i].Street,
                    DeliverToName = addresses[i].Name,
                    DeliverToState = addresses[i].State,
                    DeliverToStateCode = addresses[i].StateCode
                );
                insert delivery;
            }
            OrderItem item1 = new OrderItem(                
                OrderId = o.Id,
                Product2Id = products[0].Id,
                unitPrice = 50,
                ListPrice = 50,
                Quantity = 2,
                TotalLineAmount = 100
            );
            OrderItem item2 = new OrderItem(                
                OrderId = o.Id,
                Product2Id = products[1].Id,
                unitPrice = 75,
                ListPrice = 75,
                Quantity = 4,
                TotalLineAmount = 300
            );
            items.add(item1);
            items.add(item2);
            i++;
        }
        insert items;
    }   
}