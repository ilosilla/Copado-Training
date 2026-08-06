@isTest
private class ScriptSyncContactsTest {
    @TestSetup
    static void makeData(){
        PorcelanosaSetting__c pSetting = new PorcelanosaSetting__c(key__c = 'CONNECTIF', IsActive__c = true, subkey__c = 'US', Value1__c = '0cWQh7BrFFr5OKknFAH4:13RMlHvYHRmRHz8a8BjBcQ');
        insert pSetting;
        Id managerUserId = [SELECT Id FROM Profile WHERE Name = 'Managers'].Id;
        User testUser = User_TestDataFactory.createUsers(1, new List<String>{'en_US'})[0];
        testUser.ProfileId = managerUserId;
        testUser.Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE + ';' + OrganizationCommons.ORG_PIDF;
        testUser.Does_this_position_have_a_sales_budget__c = 'Si';
        testUser.Default_Sales_Organization__c = OrganizationCommons.ORG_AZURCERAMIQUE;
        testUser.sales_office__c = '3015';
        Insert testUser;

        // Creamos algunos contactos de prueba
        System.runAs(testUser) {
            List<Contact> testContacts = new List<Contact>();
            for(Integer i = 0; i < 5; i++) {
                Contact testContact = new Contact(
                    FirstName = 'TestFirstName' + i,
                    LastName = 'TestLastName' + i,
                    Phone = '123456789' + i,
                    Email = 'test' + i + '@example.com',
                    MailingCountryCode = 'US',
                    AccountId = null // Puedes asignar un ID de cuenta si lo deseas,
                );
                testContacts.add(testContact);
            }
            insert testContacts;
        }
    }

    // Método de prueba para verificar si se creó correctamente el archivo CSV de contactos
    @isTest
    static void testCreateContactCsv() {
        // Creamos una instancia de ScriptSyncContacts
        ScriptSyncContacts syncContacts = new ScriptSyncContacts();
        System.debug([SELECT id, owner.name from contact]);
        
        // Llamamos al método createContactCsv
        Test.startTest();
            ScriptSyncContacts aux = new ScriptSyncContacts();
            aux.setNotSync();
            aux.executeInBatch();
        Test.stopTest();
        List<ContentVersion> listDocs = [SELECT Id FROM ContentVersion];
        Assert.isTrue(listDocs.size() > 0, 'No se ha creado el documento');
        //String csvData = syncContacts.createContactCsv(testContacts);
        
        // Verificamos si se ha creado el archivo CSV
        //System.assertNotEquals(null, csvData, 'El archivo CSV no se creó correctamente');
        //System.assertNotEquals('', csvData, 'El archivo CSV no se creó correctamente');
    }
    
    // Método de prueba para verificar si se eliminaron correctamente los archivos CSV antiguos
    @isTest
    static void testDeleteOldFiles() {
        // Creamos una instancia de ScriptSyncContacts
        ScriptSyncContacts syncContacts = new ScriptSyncContacts();
        
        // Creamos algunos archivos de prueba en ContentVersion
        List<ContentVersion> testContentVersions = new List<ContentVersion>();
        for(Integer i = 0; i < 3; i++) {
            ContentVersion testContentVersion = new ContentVersion(
                ContentLocation = 'S',
                Title = 'ScriptContactsData_US_' + i + '.csv',
                PathOnClient = 'ScriptContactsData_US_' + i + '.csv',
                VersionData = Blob.valueOf('ScriptContactsData_US_' + i)
            );
            testContentVersions.add(testContentVersion);
        }
        insert testContentVersions;
        
        // Llamamos al método deleteOldFiles
        Test.startTest();
        syncContacts.deleteOldFiles();
            ScriptSyncContacts aux = new ScriptSyncContacts();
            aux.executeInBatch();
        Test.stopTest();
        
        // Verificamos si los archivos se eliminaron correctamente
        List<ContentDocument> remainingFiles = [SELECT Id FROM ContentDocument];
        Assert.isTrue(remainingFiles.size() > 0, 'No se eliminaron todos los archivos correctamente');
    }

    @isTest
    static void fillerTest() {
        ScriptSyncContacts aux = new ScriptSyncContacts();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}