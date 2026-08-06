@isTest private class SalesOrgsSelectorTest {

    @TestSetup static void makeData(){
        DataFactoryOrganization.createData();
    }

    @isTest private static void testSelectBySAPId() {
        Sales_Org__c model = [select Id, SalesOrg__c from Sales_Org__c limit 1];

        Test.startTest();
        Sales_Org__c result = new SalesOrgsSelector().selectBySAPId( new Set<String>{model.SalesOrg__c})[0];
        Test.stopTest();

        System.assertEquals(model.Id, result.Id, 'Incorrect Sales Org');
    }
}