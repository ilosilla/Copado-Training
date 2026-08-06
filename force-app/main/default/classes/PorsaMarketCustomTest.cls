@IsTest
private class PorsaMarketCustomTest {

    // === MOCKS ===

    // Mock combinado para simular respuestas de Account y Project
    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Simulamos que tanto account como project devuelven datos válidos
            res.setBody('[' +
                '{' +
                    '"Id": "12345",' +
                    '"Name": "Test Account",' +
                    '"Street": "123 Main St",' +
                    '"City": "Paris",' +
                    '"State": "IDF",' +
                    '"PostCode": "75000",' +
                    '"CountryCode": "FR",' +
                    '"Phone": "0123456789",' +
                    '"Email": "test@example.com"' +
                '}' +
            ']');
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    // === TESTS ===

    @IsTest
    static void testReadCustomSuccess() {
        // Simulamos respuesta HTTP exitosa
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        // Línea CSV simulada: índices según readCustom()
        // [0]=pmService, [2]=pmProjectId, [3]=pmAccountId, [4]=user, [5]=ownerEmail, [6]=ownerName, [7]=dateParam
        List<String> csv = new List<String>{
            'FR',                 // pmService
            'unused',             // index 1
            'PRJ123',             // pmProjectId
            'ACC123',             // pmAccountId
            'userTest',           // user
            'owner@test.com',     // ownerEmail
            'Owner Name',         // ownerName
            '2025-09-10'          // dateParam
        };

        // Ejecutamos el método
        PorsaMarketCustom custom = PorsaMarketCustom.readCustom(csv);

        // === ASSERTS ===
        System.assertNotEquals(null, custom, 'Custom object must not be null');
        System.assertEquals('ACC123', custom.accountId, 'AccountId incorrecto');
        System.assertEquals('PRJ123', custom.projectId, 'ProjectId incorrecto');
        System.assertEquals('FR', custom.pmService, 'pmService incorrecto');
        System.assertEquals('owner@test.com', custom.ownerEmail, 'Owner email incorrecto');
        System.assertEquals('Owner Name', custom.ownerName, 'Owner name incorrecto');
        System.assertNotEquals(null, custom.dataAccount, 'Account data should not be null');
        System.assertNotEquals(null, custom.dataProject, 'Project data should not be null');
    }

    @IsTest
    static void testReadCustomErrorHandling() {
        // Simulamos fallo HTTP
        Test.setMock(HttpCalloutMock.class, new MockError());

        List<String> csv = new List<String>{
            'FR', 'unused', 'PRJ123', 'ACC123', 'userTest', 'owner@test.com', 'Owner Name', '2025-09-10'
        };

        try {
            PorsaMarketCustom.readCustom(csv);
            System.assert(false, 'Debe lanzarse excepción si falla el callout');
        } catch (Exception e) {
            // Si tu clase lanza su propia excepción personalizada, cámbiala aquí
            System.assert(e.getMessage() != null, 'Debe tener mensaje de error');
        }
    }

    @IsTest
    static void testReadCustomInvalidCsv() {
        // Prueba con CSV incompleto para ver si lanza error
        List<String> invalidCsv = new List<String>{ 'FR' }; // sólo un elemento

        try {
            PorsaMarketCustom.readCustom(invalidCsv);
            System.assert(false, 'Debe lanzar excepción si CSV es inválido');
        } catch (Exception e) {
            System.assert(true, 'Excepción correctamente lanzada');
        }
    }
}