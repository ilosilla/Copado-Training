@isTest public with sharing class DataFactoryECommerceTest {

    @isTest private static void testCreateCart() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();

        Test.startTest();
        WebCart cart = factory.createCart();
        Test.stopTest();

        Assert.isNotNull(cart.Id, 'Cart should have been created');
        CartItem[] items = [SELECT Id FROM CartItem WHERE CartId = :cart.Id];
        Assert.isTrue(items.size() > 0, 'Cart should have at least one item');
    }

    @isTest private static void buildEcommerceTest() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();

        WebStore store = [select Id from WebStore limit 1];        
        Assert.isNotNull(store);

        PORSAStoreSettings__c settings0 = new PORSAStoreSettings__c();
        settings0.StoreId__c = store.Id;
        settings0.Name = 'TEST SETTINGS';
        settings0.EnablePIMSync__c = true;
        insert settings0;

        // ---------
        // Leemos la lista de store ids que tenemso que soncronizar
        PORSAStoreSettings__c[] settings = [select Id, StoreId__c from PORSAStoreSettings__c where EnablePIMSync__c = true];
        List<String> stores = TypeConversionCommons.extractFieldValues(settings, 'StoreId__c');
        Assert.isTrue(stores.size() > 0);

        // Ahora la lista de Buyer Groups
        WebStoreBuyerGroup[] buyerGroups = [select Id, BuyerGroupId from WebStoreBuyerGroup where WebStoreId in :stores];
        Assert.isTrue(buyerGroups.size() > 0);

        List<String> buyers = TypeConversionCommons.extractFieldValues(buyerGroups, 'BuyerGroupId');
        Assert.isTrue(buyers.size() > 0);

        // Y finalmente la lista de Entitlement Policies
        CommerceEntitlementBuyerGroup[] entitlements = [select PolicyId from CommerceEntitlementBuyerGroup where BuyerGroupId in :buyers] ;
        Assert.isTrue(entitlements.size() > 0);
        
        Set<Id> policies = new Set<Id>();
        for (CommerceEntitlementBuyerGroup entitlement :entitlements) {
            policies.add(entitlement.PolicyId);
        }
        Assert.isTrue(policies.size() > 0);
        List<CommerceEntitlementProduct> eps = [
            select 
                ProductId, Product.StockKeepingUnit, Product.Name, Product.Umv__c, Product.PcsXBox__c, 
                Product.M2XBox__c, Product.PesoUMV__c 
            from CommerceEntitlementProduct 
            where PolicyId in :policies
        ];
        Assert.isTrue(eps.size() > 0);
    }


}