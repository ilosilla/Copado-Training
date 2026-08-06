@isTest
private class StorageServiceTest {

    // Clase mock para simular respuestas de SAP CPI
    private class SAPCPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getMethod() == 'PUT') {
                res.setStatusCode(200);
                res.setBody('{"status":"success","message":"File saved"}');
            } else if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"data":"VGhpcyBpcyBhIHRlc3QgZmlsZQ=="}'); // Base64 de "This is a test file"
            } else if (req.getMethod() == 'DELETE') {
                res.setStatusCode(204);
                res.setBody('');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"Invalid request"}');
            }

            return res;
        }
    }

    // Mock específico para simular error en DELETE
    private class SAPCPIMockWithError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal server error"}');
            return res;
        }
    }

    @isTest
    static void testSaveFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        String path = '/v1/storage/reports';
        String fileName = 'testfile.txt';
        Blob content = Blob.valueOf('This is a test file');
        Boolean isBase64 = false;

        Test.startTest();
        Map<String, Object> result = StorageService.saveFile(path, fileName, content, isBase64);
        Test.stopTest();

        System.assertEquals('success', result.get('status'));
        System.assertEquals('File saved', result.get('message'));
    }

    @isTest
    static void testReadFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        String fullPath = '/v1/storage/reports/testfile.txt';

        Test.startTest();
        StorageService.StorageServiceFile file = StorageService.readFile(fullPath);
        Test.stopTest();

        System.assertEquals('testfile.txt', file.filename);
        System.assert(file.data != null);
    }

    @isTest
    static void testDeleteFile() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMock());

        StorageService service = new StorageService();

        Test.startTest();
        Boolean success = service.deleteFile('/v1/storage/reports/testfile.txt');
        Test.stopTest();

        System.assertEquals(true, success);
    }

    @isTest
    static void testDeleteFileWithException() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        Test.setMock(HttpCalloutMock.class, new SAPCPIMockWithError());

        StorageService service = new StorageService();

        Test.startTest();
        Boolean success = service.deleteFile('/v1/storage/reports/fail.txt');
        Test.stopTest();

        System.assertEquals(false, success);
    }
}