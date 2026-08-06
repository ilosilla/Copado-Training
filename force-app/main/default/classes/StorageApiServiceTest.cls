@isTest
private class StorageApiServiceTest {

    // Mock para simular respuestas de SAP CPI
    private class SAPCPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getMethod() == 'GET' && req.getEndpoint().contains('/folder')) {
                // Simula respuesta de readFolder
                res.setStatusCode(200);
                res.setBody('{"folder":"reports","items":[{"name":"file1.txt","type":"file","size":123,"modified":"2025-04-25T10:00:00Z","url":"https://example.com/file1.txt"}],"totalItems":1}');
            } else if (req.getMethod() == 'GET') {
                // Simula respuesta de readFile
                res.setStatusCode(200);
                res.setBody('VGhpcyBpcyBhIHRlc3QgZmlsZQ=='); // Base64 de "This is a test file"
            } else if (req.getMethod() == 'PATCH') {
                // Simula respuesta de moveFile
                res.setStatusCode(200);
                res.setBody('{"status":"success","message":"File moved"}');
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

        StorageApiService service = new StorageApiService();
        Test.startTest();
        StorageApiService.StorageApiFolderResult result = service.readFolder('folder');
        Test.stopTest();

        System.assertEquals('reports', result.folder);
        System.assertEquals(1, result.totalItems);
        System.assertEquals('file1.txt', result.items[0].name);
    }

    @isTest
    static void testReadFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        StorageApiService service = new StorageApiService();
        Test.startTest();
        String result = service.readFile('folder/file1.txt');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testMoveFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        StorageApiService service = new StorageApiService();
        Test.startTest();
        String response = service.moveFile('folder/file1.txt', 'folder/archive/file1.txt');
        Test.stopTest();

        System.assertNotEquals(null, response);
        System.assert(response.contains('success'));
    }
}