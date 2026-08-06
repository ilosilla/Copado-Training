@isTest public with sharing class SAPStatusControllerTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();
    }

    @isTest private static void getComponentData() {
        Account acc = DataFactoryAccount.createPersonAccounts(1)[0];        
        DataFactoryAccount.autoInsert = false;
        DataFactoryOrganization.createData();
        List<Sales_Relationship__c> relations = new List<Sales_Relationship__c>();
        relations.add(DataFactoryAccount.createSalesRelation(acc, OrganizationCommons.ORG_SOUTH_EAST, '60', '2552'));
        relations.add(DataFactoryAccount.createSalesRelation(acc, OrganizationCommons.ORG_SOUTH_EAST, '70', '2552'));
        relations.add(DataFactoryAccount.createSalesRelation(acc, OrganizationCommons.ORG_NORTH_WEST, '70', '2541'));
        insert relations;
        DataFactoryAccount.autoInsert = true;

        SAPStatusController.SAPStatusDTO dto = SAPStatusController.getComponentData(acc.Id, OrganizationCommons.ORG_SOUTH_EAST);
        List<Map<String,String>> orgs = dto.salesOrgs;
        System.assertEquals(2, orgs.size(), 'There should be have been 2 sales organizations');
        Map<string,string> item = orgs[0];
        System.assertEquals(OrganizationCommons.ORG_SOUTH_EAST, item.get('value'), 'First sales org should have been ' + OrganizationCommons.ORG_SOUTH_EAST);
        System.assertNotEquals('', dto.defaultOrg, 'Default sales org not found');
        System.assertNotEquals(0, dto.documents.size(), 'SAP documents not read');
    }
}