@isTest public with sharing class SAPCreditControlServiceTest {

    @testSetup public static void testSetup() {
        DataFactoryAccount.createAccounts(1);
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    public static void setMocker() {
        Test.setMock(HttpCalloutMock.class, new Mocker());
    }

    @isTest private static void test001() {   
        Account acc = [SELECT Id, SAP_Id__c FROM Account LIMIT 1];  
        acc.SAP_Id__c = '0002101523';
        update acc;   
        SAPCreditControlServiceTest.setMocker();
        Test.startTest();
        SAPCreditControlService.CreditResultDTO resultDTO = SAPCreditControlService.retrieveCreditStatus(acc.Id, '502');
        Test.stopTest();
        Assert.isTrue(resultDTO.creditLimit > 0, 'Expected credit limit greater than zero');
    }
    
    public class Mocker implements HttpCalloutMock {        
        public Boolean testError = false;
        public String defaultJson = '{"customerCode":"0002101523","companyCode":"610","creditCategory":"004","currencyCode":"USD","creditLimit":10000.0,"creditCommitted":0,"creditUtilizationRate":0,"globalCreditOk":true,"financeBlock":false,"requiresDeposits":false,"blockedByUnpaidItems":false,"blockedByOverdueItems":false,"blockedByOverdueOthers":false,"blockedByCreditLimit":false,"creditStatus":"CUSTOMER CREDIT STATUS IS OK"}';
        public String json = this.defaultJson;

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response            
            request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            if (this.testError) {
                mockResponse.setStatusCode(400);
                mockResponse.setBody('Generic Error');
            } else {
                mockResponse.setStatusCode(200);
                mockResponse.setBody(json);
            }
            return mockResponse;
        }
    }}