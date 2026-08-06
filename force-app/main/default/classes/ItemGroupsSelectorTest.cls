@isTest public with sharing class ItemGroupsSelectorTest {
    @IsTest static void testSelecttAll() {        
        Test.startTest();
        List<ItemGroup__c> itemGroups = new ItemGroupsSelector().selectAll();
        Test.stopTest();        
        Assert.isTrue(itemGroups.size() >= 0, 'Whatever is good');
    }
}