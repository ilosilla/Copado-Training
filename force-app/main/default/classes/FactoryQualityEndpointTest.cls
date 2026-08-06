@isTest public with sharing class FactoryQualityEndpointTest {

    @TestSetup static void makeData(){
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

    @isTest private static void testEndpoint() {
        // Retrieve the claims
        Case[] claims =[select Id, Status from Case];
        for (Case claim : claims) {
            claim.Liability__c = 'G1';
            claim.Warranty__c = 'NO';
            claim.SupplyInstallation__c = true;
            claim.Status = 'Closed';
        } 
        Test.startTest();
        update claims;        
        Test.stopTest();
        SAPRequestQueue__c[] items = [select Id, ActionRequested__c from SAPRequestQueue__c];
        Assert.areEqual(3, items.size(), 'There should be three items in the queue');
        Assert.areEqual('CREATE', items[0].ActionRequested__c, 'The first item should be the CREATE');
        Assert.areEqual('CREATE', items[1].ActionRequested__c, 'The second item should be the CREATE');
        Assert.areEqual('CREATE', items[2].ActionRequested__c, 'The third item should be the CREATE');
    }

}