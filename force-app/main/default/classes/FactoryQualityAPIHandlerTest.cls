@isTest public with sharing class FactoryQualityAPIHandlerTest {

    @TestSetup static void makeData(){
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dummy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);

        PORSAIntegrationSettings__c settings = new PORSAIntegrationSettings__c();
        settings.SendClaims__c = true;
        insert settings;

        DataFactoryCase.createClaims(1);
    }

    @isTest private static void test001() {
        Test.setMock(HttpCalloutMock.class, new FactoryQualityAPIHandlerTest.Mocker());
        Case[] claims = [select Id from Case];
        for (Case claim : claims) {
            claim.Liability__c = 'G1';
            claim.Warranty__c = 'NO';
            claim.SupplyInstallation__c = true;
            claim.Status = 'Closed';
        } 
        Test.startTest();
        update claims;
        Test.stopTest();

        SAPRequestQueue__c[] items = [select Id, Status__c, Message__c from SAPRequestQueue__c];
        Assert.areEqual(1, items.size(), 'There should be an item in the queue');
        String status = items[0].Status__c.toLowerCase();
        Assert.areEqual('processed', status, 'Status not expected ' + status);
    }

    @isTest private static void test002() {
        Test.setMock(HttpCalloutMock.class, new FactoryQualityAPIHandlerTest.Mocker());
        Case theCase = [select Id from Case limit 1];

        // Crear el archivo como ContentVersion
        ContentVersion file = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert file;

        // Obtener el ContentDocumentId generado automáticamente
        Id contentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :file.Id
        ].ContentDocumentId;

        // Crear el vínculo entre el archivo y el caso
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = theCase.Id,
            ShareType = 'V', // Viewer access
            Visibility = 'AllUsers'
        );
        insert link; 

        Test.startTest();
        theCase.Liability__c = 'G1';
        theCase.Warranty__c = 'NO';
        theCase.SupplyInstallation__c = true;
        theCase.Status = 'Closed';
        update theCase;   
        Test.stopTest();

        SAPRequestQueue__c[] items = [select Id, Status__c, Message__c, SAPAPIHandler__c, RequesterId__c, Parameter__c from SAPRequestQueue__c];
        Assert.areEqual(2, items.size(), 'There should be 2 items in the queue');
        String status = items[0].Status__c.toLowerCase();
        Assert.areEqual('processed', status, 'Status not expected ' + status + ' in API handler ' + items[0].SAPAPIHandler__c);

    }

    public class Mocker implements HttpCalloutMock {
        
        public Boolean testError = false;

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response            
            request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            if (this.testError) {
                String json = '{"status":"false","date":"2025-06-25 08:59:14","data":9,"message":"Dummy error","automaticChanges":false}';
                mockResponse.setStatusCode(400);
                mockResponse.setBody(json);
            } else {
                String json = '{"status":"success","date":"2025-06-25 08:59:14","data":9,"message":"Message stored successfully","automaticChanges":false}';
                mockResponse.setStatusCode(200);
                mockResponse.setBody(json);
            }
            return mockResponse;
        }
    }
    

}