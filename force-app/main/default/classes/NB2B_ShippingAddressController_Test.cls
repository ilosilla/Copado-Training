/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 02-03-2023
 * @last modified by  : EHG@nubika.com
**/
@IsTest
public with sharing class NB2B_ShippingAddressController_Test {

    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        insert acc;
        WebStore webStore = new WebStore(Name='United Kingdom');
        insert webStore;
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=acc.Id,PoNumber='test');
        insert cart;
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery2',NB2B_DeliveryDate__c = Date.today(),NB2B_OrderCode__c='1234');
        insert cartDeliveryGroup;
    }
    

    @IsTest
    public static void test1(){
        CartDeliveryGroup cg = [SELECT NB2B_DeliveryDate__c,NB2B_OrderCode__c FROM CartDeliveryGroup WHERE Name = 'Default Delivery2' LIMIT 1];
        NB2B_ShippingAddressController.wrappData result;
        Test.startTest();
            result = NB2B_ShippingAddressController.getDataCartGroup(cg.Id);
        Test.stopTest();

        Assert.areEqual(result != null,true);
    }

    @IsTest
    public static void getUserCountryTest(){
        NB2B_ShippingAddressController.wrappData result;
        Test.startTest();
            NB2B_ShippingAddressController.getUserCountry('invalidId');
        Test.stopTest();
    }
}