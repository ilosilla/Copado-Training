@isTest public class FactoryQualityFileAPIHandlerTest {

     @TestSetup static void makeData(){
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https://dummy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);

        PORSAIntegrationSettings__c settings = new PORSAIntegrationSettings__c();
        settings.SendClaims__c = true;
        insert settings;
        Case[] claims = DataFactoryCase.createClaims(1);
        
        // Crear dos archivos de texto como ContentVersion
        List<ContentVersion> files = new List<ContentVersion>();
        files.add(new ContentVersion(
            Title = 'Archivo 1',
            PathOnClient = 'archivo1.txt',
            VersionData = Blob.valueOf('test file 1')
        ));
        files.add(new ContentVersion(
            Title = 'Archivo 2',
            PathOnClient = 'archivo2.txt',
            VersionData = Blob.valueOf('test file 2')
        ));
        insert files;

        // Obtener los ContentDocumentIds para crear los enlaces
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion version : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :files]) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = version.ContentDocumentId,
                LinkedEntityId = claims[0].Id,
                ShareType = 'V'  // V = Viewer
            ));
        }
        insert links;
    }

    @isTest private static void testQueue() {
         // Retrieve the claims
        Case[] claims =[select Id, Status from Case];
        for (Case claim : claims) {
            claim.Liability__c = 'G1';
            claim.Warranty__c = 'NO';
            claim.SupplyInstallation__c = true;
            claim.Status = 'Closed';
        } 

        String customResponse = JSON.serialize(
            new Map<String, Object> {
                'status' => 'success',
                'date' => '2025-08-01 13:13:19',
                'data' => 17,
                'message' => 'Message stored successfully',
                'automaticChanges' => false
            }
        );
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = customResponse;
        Test.setMock(HttpCalloutMock.class, mocker);
        Test.startTest();
        update claims;        
        Test.stopTest();

        SAPRequestQueue__c[] items = [
            SELECT Id, Status__c, Message__c, SAPAPIHandler__c, Sequence__c
            FROM SAPRequestQueue__c
            ORDER BY Sequence__c
        ];

        Assert.areEqual(3, items.size(), 'There should be three items in the queue');
        Assert.areEqual('PROCESSED', items[0].Status__c, 'The status 1 shoudl be PROCESSED');
        
        Assert.areEqual(
            'PROCESSED',
            items[1].Status__c,
            'Item 2 handler=' + items[1].SAPAPIHandler__c +
            ' message=' + items[1].Message__c +
            ' sequence=' + items[1].Sequence__c
        );

        Assert.areEqual('PROCESSED', items[2].Status__c, 'The status 3 shoudl be PROCESSED');
    }
}