@isTest public with sharing class DataFactoryOrganizationTest {
    
    @isTest public static void createData() {

        DataFactoryOrganization.createData();

        List<sObject> comp = [select id, name, CompanyCode__c from Company__c];
        System.assert(comp.size() > 0, 'Error creating companies');

        List<sObject> orgs = [select id, name, Company__c from Sales_Org__c];        
        System.assert(orgs.size() > 0, 'Error creating sales organizations');

        List<sObject> relations = [select id, name from Master_relations__c];
        System.assert(relations.size() > 0, 'Error creating master relations');
        

    }
}