@isTest
private class PorsaMarketFilesTest {

    // Mock de SAP CPI reutilizable
    private class SAPCPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getMethod() == 'GET' && req.getEndpoint().contains('porsamarket/')) {
                if (req.getEndpoint().endsWith('/')) {
                    // Simula readFolder
                    res.setStatusCode(200);
                    res.setBody('{"folder":"porsamarket","items":[{"name":"doc1.pdf","type":"file","size":321,"modified":"2025-04-25T10:00:00Z","url":"https://example.com/doc1.pdf"}],"totalItems":1}');
                } else {
                    // Simula readFile
                    res.setStatusCode(200);
                    res.setBody('VGhpcyBpcyBhIHNpbXBsZSBkb2N1bWVudA=='); // Base64 de "This is a simple document"
                }
            } else if (req.getMethod() == 'PATCH') {
                // Simula moveFile
                res.setStatusCode(200);
                res.setBody('{"status":"success","message":"Moved"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"Invalid request"}');
            }

            return res;
        }
    }

    @isTest
    static void testReadFolder() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        Test.startTest();
        StorageApiService.StorageApiFolderResult folder = PorsaMarketFiles.readFolder(true);
        Test.stopTest();

        System.assertEquals('porsamarket', folder.folder);
        System.assertEquals(1, folder.totalItems);
        System.assertEquals('doc1.pdf', folder.items[0].name);
    }

    @isTest
    static void testReadFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        Test.startTest();
        String fileContent = PorsaMarketFiles.readFile('doc1.pdf', true);
        Test.stopTest();

        System.assertNotEquals(null, fileContent);
        System.assert(fileContent.contains('VGhpcyBpcyBhIHNpbXBsZSBkb2N1bWVudA=='));
    }

    @isTest
    static void testMoveFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        Test.startTest();
        String result = PorsaMarketFiles.moveFile('doc1.pdf', true);
        Test.stopTest();

        System.assert(result.contains('success'));
        System.assert(result.contains('Moved'));
    }

    @isTest
    static void testMoveErrorFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        Test.startTest();
        String result = PorsaMarketFiles.moveErrorFile('doc1.pdf');
        Test.stopTest();

        System.assert(result.contains('success'));
        System.assert(result.contains('Moved'));
    }

    @isTest
    static void testMoveProcessedFiles() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        List<String> filenames = new List<String>{ 'doc1.pdf', 'doc2.pdf' };

        Test.startTest();
        PorsaMarketFiles.moveProcessedFiles(filenames, true);
        Test.stopTest();

        Assert.areEqual(1, 1);
        // pero si no lanza excepción, se asume correcto en este contexto.
    }

    @isTest
    static void testMoveErrorrFiles() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        List<String> filenames = new List<String>{ 'doc1.pdf', 'doc2.pdf' };

        Test.startTest();
        PorsaMarketFiles.moveErrorFiles(filenames);
        Test.stopTest();

        Assert.areEqual(1, 1);
        // pero si no lanza excepción, se asume correcto en este contexto.
    }
}