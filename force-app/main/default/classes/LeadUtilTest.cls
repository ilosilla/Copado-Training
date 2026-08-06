@isTest public with sharing class LeadUtilTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();
    }

    @isTest private static void isWebRequest() {
        DataFactoryLead.createWebRequest(1);
        Lead l = [select Id from Lead][0];
        System.assertEquals(true, LeadUtil.isWebRequest(l.Id), 'IsWebRequest now working');
    } // isWebRequest
    
    @isTest private static void isUSWebRequest() {
        DataFactoryLead.createUSWebRequest(1);
        Lead l = [select Id from Lead][0];
        System.assertEquals(true, LeadUtil.isUSWebRequest(l.Id), 'IsUSWebRequest now working');
    } // isWebRequest

    @isTest private static void getLeadVariant() {
        Lead l = new Lead();
        l.Source__c = 'USW';
        System.assertEquals('US', LeadUtil.getLeadVariant(l), 'Lead variant should be US');
    }

    @isTest private static void convertToPersonAccount() {
        lead l = new Lead();
        System.assertEquals(true, LeadUtil.convertToPersonAccount(l) , 'Convert should be true ');
        l.Company = 'ACME';
        System.assertEquals(false, LeadUtil.convertToPersonAccount(l) , 'Convert should be false+');
    }

    @isTest private static void testGetData() {
        DataFactoryLead.createWebRequest(1);
        Lead l = [select Id from Lead][0];
        Lead l2 = leadUtil.getData(l.Id);
        System.assertEquals(l.Id, l2.Id, 'Ids should match');
    } // isWebRequest


}