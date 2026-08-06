@IsTest
private class PorsaMarketProjectTest {

    @testSetup
    static void setupData() {
        DataFactoryOpportunity.createTradeOpportunities(1, 1);
    }

    // Mock de llamada exitosa
    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[' +
                '{' +
                '"IdProject": "PRJ123",' +
                '"Name": "Test Project",' +
                '"Street": "123 Project St",' +
                '"Street2": "Suite 10",' +
                '"State": "FR-IDF",' +
                '"PostCode": "75001",' +
                '"CountryCode": "FR",' +
                '"City": "Paris",' +
                '"TotalAmount": 100000,' +
                '"Comment": "Important project",' +
                '"New_Renovation": "Neuf"' +
                '}' +
            ']');
            return res;
        }
    }

    // Solo prueba la llamada getData() y parseo del JSON
    @IsTest
    static void testGetData() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        PorsaMarketProject pmp = new PorsaMarketProject();
        pmp.projectId = 'PRJ123';
        pmp.pmService = 'FR';

        Test.startTest();
        pmp.getData();
        Test.stopTest();

        System.assertNotEquals(null, pmp.data, 'La data no debe ser null');
        System.assertEquals('Test Project', pmp.data.Name, 'El nombre del proyecto debe coincidir');
    }

    // Prueba el método toOpportunity
    @IsTest
    static void testToOpportunity() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        PorsaMarketProject pmp = new PorsaMarketProject();
        pmp.projectId = 'PRJ123';
        pmp.pmService = 'FR';

        Test.startTest();
        pmp.getData();
        Test.stopTest();

        Opportunity opp = pmp.toOpportunity();
        System.assertEquals('Test Project', opp.Name);
        System.assertEquals('New construction', opp.Operation_Type__c);
        System.assertEquals('FRPRJ001', opp.PorsamarketId__c);
    }

    // Prueba actualizar una oportunidad existente
    @IsTest
    static void testUpdateOpportunity() {
        Opportunity existingOpp = [SELECT Id FROM Opportunity LIMIT 1];

        PorsaMarketProject pmp = new PorsaMarketProject();
        pmp.projectId = 'PRJ456';
        pmp.pmService = 'ES';

        Test.startTest();
        Opportunity updated = pmp.updateOpportunity(existingOpp.Id);
        Test.stopTest();

        System.assertEquals('ESPRJ456', updated.PorsamarketId__c);
        System.assertEquals(true, updated.Verified__c);
    }

    @isTest
    static void testReadProject() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        List<String> csv = new List<String>{
            'ES', '', 'New', 'PRJ001', '006XXXXXXXXXXXX', 'SIRET01', '001XXXXXXXXXXXX', 'user', '2024-04-25'
        };
        Test.startTest();
        PorsaMarketProject result = PorsaMarketProject.readProject(csv);
        Test.stopTest();
        System.assertNotEquals(null, result.data);
        System.assertEquals('ES', result.pmService);
        System.assertEquals('PRJ001', result.projectId);
    }

    @isTest
    static void testReadProjectAccount() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());
        List<String> csv = new List<String>{
            'ES', '', 'New', 'PRJ001', '006XYZ', 'SIRET123456', '-1', 'user', '2024-04-25'
        };

        Test.startTest();
        PorsaMarketAccount result = PorsaMarketProject.readProjectAccount(csv);
        Test.stopTest(); // Aquí se realiza el callout
        System.assertNotEquals(null, result.data);
        System.assertEquals('SIRET123456', result.accountId);
    }
}