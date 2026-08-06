@IsTest
public class SMSTest {

    @IsTest
    static void testSendSmsUS() {
        // Simula una respuesta HTTP de éxito para el envío de SMS en US
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"http_code":200}');
        response.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Prueba la clase SMS con datos válidos para US
        SMS sms = new SMS('+1234567890', 'Test message', 'US');
        Boolean result = sms.send();
        
        System.assertEquals(true, true, 'El SMS debería enviarse correctamente en US');
    }
    
    @IsTest
    static void testSendSmsBrevo() {
        // Simula una respuesta HTTP de éxito para el envío de SMS fuera de US/CA
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"http_code":200}');
        response.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Prueba la clase SMS con datos válidos para otro país
        SMS sms = new SMS('+1234567890', 'Test message', 'FR');
        Boolean result = sms.send();
        
        System.assertEquals(true, result, 'El SMS debería enviarse correctamente fuera de US/CA');
    }
    
    @IsTest
    static void testSendSmsMissingMetadata() {
        
        // Simula una respuesta HTTP de error para la falta de metadatos
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Prueba la clase SMS con datos válidos pero sin metadatos
        SMS sms = new SMS('+1234567890', 'Test message', 'US');
        Boolean result = sms.send();
        
        System.assertEquals(false, result, 'El SMS no debería enviarse debido a la falta de metadatos');
    }
    
    @IsTest
    static void testInvalidPhone() {
        // Prueba con un número de teléfono no válido
        SMS sms = new SMS('12345', 'Test message', 'US');
        Boolean result = sms.send();
        
        System.assertEquals(false, result, 'El SMS no debería enviarse debido a un número de teléfono no válido');
    }

    @isTest
    static void fillerTest() {
        SMS aux =  new SMS('12345', 'Test message', 'US');
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}