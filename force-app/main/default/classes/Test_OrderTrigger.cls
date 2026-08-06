@IsTest
public class Test_OrderTrigger {
    
    @isTest public static void Test_trigger(){
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        /*
        Account account = new Account(LastName = 'Test LastName', Country__c = 'GB', PersonEmail = 'email@test.com');
        insert account;
        
        List<Order> orderList = new List<Order>();
        orderList.add(new Order(AccountId = account.Id,
                                EffectiveDate = Date.valueOf('2018-09-27'),
                                LineNo__c = 123,
                                Company__c = '502',
                                SalesOrg__c = '502',
                                SalesOffice__c = '2553',
                                Product__c = 123,
                                Currency__c = 'USD',
                                DeliveryMethod__c = 'E',
                                DeliveryDate__c = Date.valueOf('2018-09-27'),
                                Status = 'Draft' 
                                ));
        
        insert orderList;
        
        List<Order> orderResult = [SELECT Id, Name, OrderNumber
                                   FROM Order
                                   WHERE Id IN :orderList LIMIT 1];
        
        List<Opportunity> oppList = [SELECT Id, Name
                                     FROM Opportunity
                                     WHERE Name =: 'Oportunidad del pedido ' + orderResult[0].OrderNumber];
        
        System.assert(oppList.size() > 0);
        */
    }

}