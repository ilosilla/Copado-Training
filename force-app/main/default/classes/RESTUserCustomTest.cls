@isTest
private class RESTUserCustomTest {

    @isTest
    static void testMethods_UserDoesNotExist() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/UserCustom/methods';
        request.addParameter('function', 'USEREXISTS');
        request.addParameter('email', 'nonexistent@example.com');
        RestContext.request = request;
        RestContext.response = response;

        // Llamada al método que se va a probar
        RESTUserCustom.methods();

        // Verificación
        System.assertEquals(500, response.statusCode, 'Se esperaba un código de estado 500');
        // Puedes agregar más aserciones para verificar el cuerpo de la respuesta si es necesario
    }

    @isTest
    static void testMethods_Ping() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/UserCustom/methods';
        request.addParameter('function', 'PING');
        RestContext.request = request;
        RestContext.response = response;

        // Llamada al método que se va a probar
        RESTUserCustom.methods();

        // Verificación
        System.assertEquals(200, response.statusCode, 'Se esperaba un código de estado 200');
        // Puedes agregar más aserciones para verificar el cuerpo de la respuesta si es necesario
    }

    @isTest
    static void testMethods_NoFunctionParam() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/UserCustom/methods';
        RestContext.request = request;
        RestContext.response = response;

        // Llamada al método que se va a probar
        RESTUserCustom.methods();

        // Verificación
        System.assertEquals(500, response.statusCode, 'Se esperaba un código de estado 500');
        // Puedes agregar más aserciones para verificar el cuerpo de la respuesta si es necesario
    }

    @isTest
    static void testMethods_UserExists_NullUserId() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/UserCustom/methods';
        request.addParameter('function', 'USEREXISTS');
        request.addParameter('email', 'testuser@example.com');
        RestContext.request = request;
        RestContext.response = response;

        // Mockeo del método userExists para que devuelva null
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        RESTUserCustom.methods();
        Test.stopTest();

        // Verificación
        System.assertEquals(500, response.statusCode, 'Se esperaba un código de estado 500');
        // Puedes agregar más aserciones para verificar el cuerpo de la respuesta si es necesario
    }

    // Clase interna para simular la respuesta de una llamada HTTP
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody('{ "id" : "mockedUserId" }');
            res.setStatusCode(200);
            return res;
        }
    }
}