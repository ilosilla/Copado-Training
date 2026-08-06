@isTest public with sharing class PIMProductsSelectorTest {

    @isTest static void test001() {
        Id fakeId = UserInfo.getUserId();
        List<PIMProduct__c> results = new PIMProductsSelector().selectByProductId(new Set<Id>{fakeId});
        Assert.areEqual(0, results.size(), 'No results expected');
    }
}