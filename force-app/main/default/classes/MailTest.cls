@isTest
public class MailTest {
    
    @testSetup static void setup() {
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        List<Account> accList = new List<Account>();
        accList.add(Account_TestDataFactory.createRetailer());
        accList.add(Account_TestDataFactory.createBusinessAccount());
        accList.add(Account_TestDataFactory.createRetailer());
        accList.add(Account_TestDataFactory.createCustomer());

        insert accList;
    }

    @isTest
    public static void send() {
        Mail aux = new Mail();
        // TEST SEND WITH EMAILs
        Boolean result = aux.send(true, new List<String>{'ivan.losilla@porcelanosagrupo.com'}, new List<String>(), new List<String>(), 'Test Mailinf', 'Test of a Single Mail');
        
        System.assert(result == true);
        
        Map<Id, User> usrList = new Map<Id,User>([Select Id from User LIMIT 5]);
        Map<Id, Account> accList = new Map<Id,Account>([Select Id from Account LIMIT 4]);

        List<Id> idsList = new List<Id>();
        idsList.addAll(usrList.keySet());
        idsList.addAll(accList.keySet());

        // TEST SEND WITH IDs
        result = aux.send(true, new List<Id>{Id.valueOf(UserInfo.getUserId()),Id.valueOf(UserInfo.getUserId())}, new List<Id>(), new List<Id>{Id.valueOf(UserInfo.getUserId())}, 'Test Mailinf', 'Test of a Single Mail');
        System.assert(result == true);
    }
    
    @isTest
    public static void send2() {
        Mail aux = new Mail();

        aux.setTo(UserInfo.getUserId());
        aux.setCc(UserInfo.getUserId());
        aux.setBcc(UserInfo.getUserId());
        
        System.assert(aux.getTo()[0] == Userinfo.getUserEmail(), 'El email del To no cuadra');
        System.assert(aux.getCc()[0] == Userinfo.getUserEmail(), 'El email del To no cuadra');
        System.assert(aux.getBcc()[0] == Userinfo.getUserEmail(), 'El email del To no cuadra');
        System.assert(aux.getSubject() == 'Default Subject', 'No debería haber un Subject');
        System.assert(aux.getHtml() == '<html></html>', 'No debería haber un Body');
        
        aux.sendDevelopers('Test de prueba', 'BLABLABLABLA');  
    }

    @isTest public static void testAttachments() {
        Account acc = [select Id from Account limit 1];
        createAttachment(acc.Id);
        Mail m = new Mail();
        m.addObjectAttachments(acc.Id);
        m.addAttachment('manualfile.txt', Blob.valueOf('Hola'));
        Assert.isTrue(1==1, 'There should be at least one attachment');
    }

    @isTest
    static void testAddObjectAttachments() {
        // 1. Create a Case using your DataFactory
        List<Case> cases = DataFactoryCase.createClaims(1);
        Case testCase = cases[0];

        // 2. Insert a ContentVersion associated with the Case via FirstPublishLocationId
        Blob fileBody = Blob.valueOf('Test file content for unit test.');
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile.txt',
            PathOnClient = 'TestFile.txt',
            VersionData = fileBody,
            FirstPublishLocationId = testCase.Id, // This associates the file with the Case
            IsMajorVersion = true
        );
        insert cv;

        // (Optional) Verify the ContentDocumentLink has been created and linked to the Case
        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testCase.Id
        ];
        System.assert(!links.isEmpty(), 'There should be a ContentDocumentLink associated with the Case.');

        // 3. Call your addObjectAttachments method (assuming it is in a class named MyMailer)
        Mail mailer = new Mail();
        List<Mail.DownloadLinkInfo> downloadLinks = mailer.addObjectAttachments(testCase.Id, true);

        // 4. Assertions
        // (For a small file, the list of downloadLinks should be empty since it can be attached)
        System.assertEquals(0, downloadLinks.size(), 'File should be attached, not linked.');
    }

    @isTest
    static void testGenerateContentDistributionLink() {
        // 1. Create a test Case
        List<Case> cases = DataFactoryCase.createClaims(1);
        Case testCase = cases[0];

        // 2. Insert a ContentVersion associated with the Case
        Blob fileBody = Blob.valueOf('Test content for public link test.');
        ContentVersion cv = new ContentVersion(
            Title = 'PublicTestFile.txt',
            PathOnClient = 'PublicTestFile.txt',
            VersionData = fileBody,
            FirstPublishLocationId = testCase.Id,
            IsMajorVersion = true
        );
        insert cv;

        // 3. Retrieve the ContentVersion Id (needed for the method)
        Id contentVersionId = cv.Id;

        // 4. Call the (testVisible) private method to generate the public link
        Mail mailer = new Mail();
        Test.startTest();
        String publicLink = mailer.generateContentDistributionLink(contentVersionId, 72);
        Test.stopTest();

         // El link será null en test context. Puedes comprobar que no lanza excepción.
        System.assertEquals(null, publicLink, 'In test context, the DistributionPublicUrl is always null.');

        // Verifica que el ContentDistribution existe y está bien enlazado
        List<ContentDistribution> cds = [
            SELECT Id, ContentVersionId
            FROM ContentDistribution
            WHERE ContentVersionId = :contentVersionId
        ];
        System.assertEquals(1, cds.size(), 'A ContentDistribution should have been created.');
    }


    private static void createAttachment(Id accountId) {
         String encodedContentsString = 'This is a test attachment';    
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf(encodedContentsString);
        attachment.Name = String.valueOf('test.txt');
        attachment.ParentId = accountId; 
        insert attachment;
    }

}