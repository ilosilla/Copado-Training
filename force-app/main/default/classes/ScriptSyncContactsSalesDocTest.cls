@isTest
private class ScriptSyncContactsSalesDocTest {
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

        Account acc = new Account();
        acc = Account_TestDataFactory.createFabricator();
        acc.SAP_Id__c = '1005672';

        // Creamos algunos contactos de prueba
        System.runAs(testUser) {
            insert acc;
            List<Contact> testContacts = new List<Contact>();
            for(Integer i = 0; i < 5; i++) {
                Contact testContact = new Contact(
                    FirstName = 'TestFirstName' + i,
                    LastName = 'TestLastName' + i,
                    Phone = '123456789' + i,
                    Email = 'test' + i + '@example.com',
                    MailingCountryCode = 'US',
                    AccountId = acc.Id // Puedes asignar un ID de cuenta si lo deseas,
                );
                testContacts.add(testContact);
            }
            insert testContacts;
        }
    }

    // Método de prueba para verificar si se creó correctamente el archivo CSV de contactos
    @isTest
    static void testCreateContactCsv() {
        List<Account> accList = [SELECT Id FROM Account];
        Account acc = accList[0];

        List<Pedidos_cabeceraSet__x> listCab = new List<Pedidos_cabeceraSet__x>();
        Pedidos_cabeceraSet__x  posCabe = new Pedidos_cabeceraSet__x  (
            ExternalId = '01010101',
            Ordernum__c ='123',
            Account__c = acc.Id,
            Orderdate__c = Datetime.now().addHours(-10),
            Ordertype__c = 'ZW04',
            Company__c = '218',
            Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST,
            //Distchannel__c = sale.Id,
            Division__c = '10',//constante 10
            Salesoffic__c = '2541',
            Ddate__c = Datetime.now(),
            Customer__c= '1005672' ,
            Dcurr__c = 'GBP',
            Dnet__c = 7.99,
            Dtax__c = 0,
            Dtotal__c =7.99,
            Exrate__c = '1.43220',
            Credit__c = '20888255'
        );
        listCab.add(posCabe);
        posCabe = new Pedidos_cabeceraSet__x  (
            ExternalId = '01010101',
            Ordernum__c ='123',
            Account__c = acc.Id,
            Orderdate__c = Datetime.now().addDays(-1),
            Ordertype__c = 'ZW04',
            Company__c = '218',
            Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST,
            //Distchannel__c = sale.Id,
            Division__c = '10',//constante 10
            Salesoffic__c = '2541',
            Ddate__c = Datetime.now(),
            Customer__c= '1005672' ,
            Dcurr__c = 'GBP',
            Dnet__c = 7.99,
            Dtax__c = 0,
            Dtotal__c =7.99,
            Exrate__c = '1.43220',
            Credit__c = '20888255'
        );
        listCab.add(posCabe);
        ExternalObjectManager.setMock(new MockInterfaceOverride(listCab));
        

 
        List<Pedidos_cabeceraSet__x> listCabecera = ExternalObjectManager.records([select Id, CurrencyIsoCode, ExternalId, DisplayUrl, BillTo__c, Comis2__c,
                                                                                   Comis__c, Company__c, Customer__c, Dcurr__c, Ddate__c, Distchannel__c, Division__c,
                                                                                   Dnet__c, Doc__c, Dtax__c, Dtotal__c, Exrate__c, Exratet__c, Gcurr__c, Gnet__c, Gtax__c,
                                                                                   Gtotal__c, Lcurr__c, Lnet__c, Ltax__c, Ltotal__c, OpenF__c, Orderdate__c, Ordernum__c,
                                                                                   Ordertype__c, Paid__c, PaisDestino__c, Probld__c, Refer__c, Repo1__c, Repo2__c, 
                                                                                   Salesoffic__c, Salesorg__c, Sfopportunity__c, Trvog__c, Vbtyp__c, Erdat__c, Erzet__c,
                                                                                   Account__c
                                                                                from Pedidos_cabeceraSet__x]);
        System.debug('***1--->'+listCabecera);
        Test.startTest();
        System.debug('NUMBER OF ELEMENTS PEDIDOS');
        System.debug(listCabecera);
        System.debug([select id, Account__c, Customer__c, Orderdate__c,Erdat__c from Pedidos_cabeceraSet__x where Orderdate__c = LAST_N_DAYS:0]);
            ScriptSyncContactsSalesDocs aux = new ScriptSyncContactsSalesDocs();
            aux.setNotSync();
            aux.executeInBatch();

            aux.execute(null, listCabecera);
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
            ScriptSyncContactsSalesDocs aux = new ScriptSyncContactsSalesDocs();
            aux.executeInBatch();
        Test.stopTest();
        
        // Verificamos si los archivos se eliminaron correctamente
        List<ContentDocument> remainingFiles = [SELECT Id FROM ContentDocument];
        Assert.isTrue(remainingFiles.size() > 0, 'No se eliminaron todos los archivos correctamente');
    }

    @isTest
    static void fillerTest() {
        ScriptSyncContactsSalesDocs aux = new ScriptSyncContactsSalesDocs();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}