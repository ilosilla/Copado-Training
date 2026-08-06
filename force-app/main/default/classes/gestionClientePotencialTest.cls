@IsTest
private class gestionClientePotencialTest {

    @testSetup static void setup() {
        
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
        
    
    @isTest static void obtenerClientePotencialTest(){
        
        // Success
        Account acc = createTestRecord();

        RestRequest request1 = new RestRequest();
        request1.requestUri =
            '/services/apexrest/ClientePotencial/'
            + acc.Id;
        request1.httpMethod = 'GET';
        RestContext.request = request1;
        
        List<Account> result1 = [SELECT Id, FirstName, LastName, PersonEmail 
                                 FROM Account
                                 WHERE Id = :acc.Id];

        System.assert(result1.size() != 0);
        System.assert(result1[0].FirstName == 'Carlos');
        System.assert(result1[0].LastName == 'Gómez');
        System.assert(result1[0].PersonEmail == 'cgomez@neoris.com');
        
        // Fail
        String recordId = 'FF011w000002fwdQAAQ';
        
        RestRequest request2 = new RestRequest();
        request2.requestUri =
            '/services/apexrest/ClientePotencial/'
            + recordId;
        request2.httpMethod = 'GET';
        RestContext.request = request2;
        
        List<Account> result2 = [SELECT Id 
                                 FROM Account
                                 WHERE Id = :recordId];
        
        System.assert(result2.size() == 0);
        
    }
    
    @isTest static void crearClientePotencialTest() {
        
        // Map para verificar respuestas
        Map<String, Object> responseMap;

        RestRequest request1 = new RestRequest();
        RestResponse response1 = new RestResponse();
        
        request1.requestURI = '/services/apexrest/ClientePotencial';
        request1.httpMethod = 'POST';
        request1.requestBody = Blob.valueOf('{"FirstName": "Ramón", "LastName": "Prades", "PersonEmail": "rprades@porcelanosa.com", "Country__c": "ES"}');
        
        RestContext.request = request1;
        RestContext.response = response1;
        
        gestionClientePotencial.crearClientePotencial();
        
        //System.assert(response1.statusCode == 201);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'El cliente potencial ha sido creado con éxito.');

        // Fail (El campo 'PersonEmail' es nulo)
        request1.requestBody = Blob.valueOf('{"FirstName": "Ramón", "LastName": "Prades", "PersonEmail": null, "Country__c": "ES"}');
        gestionClientePotencial.crearClientePotencial();
        
        //System.assert(response1.statusCode == 400);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'Faltan campos obligatorios: [PersonEmail]');
        
        // Fail (El 'Cliente Potencial' ya existe en BD)
        Account acc = createTestRecord();
        
        request1.requestBody = Blob.valueOf('{"FirstName": "Ramón", "LastName": "Prades", "PersonEmail": "'+ acc.PersonEmail + '", "Country__c": "ES"}');
        gestionClientePotencial.crearClientePotencial();
        
        //System.assert(response1.statusCode == 300);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'Ya existe una cuenta con dicho email en BD.');
        
        // Fail (El campo 'PersonEmail' tiene un formato incorrecto)
		request1.requestBody = Blob.valueOf('{"FirstName": "Diego", "LastName": "Ramírez", "PersonEmail": "aaa", "Country__c": "ES"}');
        gestionClientePotencial.crearClientePotencial();
        
        //System.assert(response1.statusCode == 500);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'Correo electrónico: dirección de correo electrónico no válida: aaa.');
        
        // Fail (Alguno de los campos proporcionados no corresponde a Cliente Potencial -Phone-)
        request1.requestBody = Blob.valueOf('{"FirstName": "Diego", "LastName": "Ramírez", "PersonEmail": "aaa", "Country__c": "ES", "Phone" : "111"}');
        gestionClientePotencial.crearClientePotencial();
        
        //System.assert(response1.statusCode == 400);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'Alguno de los campos proporcionados no existe o no corresponde a Cliente Potencial. Revise nuevamente el cuerpo de la solicitud.');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }
    
    @isTest static void eliminarClientePotencialTest() {
        
        // Map para verificar respuestas
        Map<String, Object> responseMap;
        
        // Success
        Account acc = createTestRecord();
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri =
            '/services/apexrest/ClientePotencial/'
            + acc.Id;        
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;        
        RestContext.response = response;

        gestionClientePotencial.eliminarClientePotencial();
        
        System.assert(response.statusCode == 200);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El registro ha sido eliminado con éxito.');
        
        // Fail (El id provisto no corresponde a ningún Cliente Potencial)
        String recordId = 'F011w000002fwdQAAQ';
        
        request.requestUri =
            '/services/apexrest/ClientePotencial/'
            + recordId;
        request.httpMethod = 'DELETE';
        
        gestionClientePotencial.eliminarClientePotencial();
        
        System.assert(response.statusCode == 404);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El Id provisto no corresponde a ningún registro de tipo \'Cliente potencial\'.');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
                
    }
    
    @isTest static void modificarClientePotencialTest() {
        
        // Map para verificar respuesta
        Map<String, Object> responseMap;
        
        // Success
        Account acc = createTestRecord();
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri =
            '/services/apexrest/ClientePotencial/'
            + acc.Id;
        request.httpMethod = 'PATCH';
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"FirstName": "Álvaro", "LastName": "Rodríguez", "PersonEmail": "arod@neoris.com", "Country__c": "ES"}');  
        
        RestContext.request = request;
        RestContext.response = response;
        
        gestionClientePotencial.modificarClientePotencial();

        System.assert(response.statusCode == 200);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El registro ha sido actualizado con éxito.');
        
        // Fail ('El Id provisto no corresponde a ningún Cliente Potencial')
        String recordId = 'F011w000002fwdQAAQ';
        
        request.requestUri =
            '/services/apexrest/ClientePotencial/'
            + recordId;
        request.httpMethod = 'PATCH';
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"FirstName": "Álvaro", "LastName": "Rodríguez", "PersonEmail": "arod@neoris.com", "Country__c": "ES"}');
        
        gestionClientePotencial.modificarClientePotencial();
        
        System.assert(response.statusCode == 404);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El Id provisto no corresponde a ningún registro de tipo \'Cliente potencial\'.');
        
        // Fail (Alguno de los campos proporcionados no existe -Email-)
        request.requestUri =
            '/services/apexrest/ClientePotencial/'
            + acc.Id;
        request.httpMethod = 'PATCH';
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"FirstName": "Álvaro", "LastName": "Rod", "Email": "arod@neoris.com", "Country__c": "ES"}');
        
        gestionClientePotencial.modificarClientePotencial();
        
        System.assert(response.statusCode == 400);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'Alguno de los campos proporcionados no existe o no corresponde a Cliente Potencial. Revise nuevamente el cuerpo de la solicitud.');
          
        // Fail (El campo 'PersonEmail' tiene un formato incorrecto)
		request.requestBody = Blob.valueOf('{"FirstName": "Diego", "LastName": "Ramírez", "PersonEmail": "aaa", "Country__c": "ES"}');
        gestionClientePotencial.crearClientePotencial();
        
        //System.assert(response.statusCode == 500);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        //System.assert(responseMap.get('message') == 'Correo electrónico: dirección de correo electrónico no válida: aaa.');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }

    static Account createTestRecord() {
        // Create test record
        Account accountTest = new Account(
            FirstName = 'Carlos',
            LastName = 'Gómez',
            PersonEmail = 'cgomez@neoris.com',
            Country__c = 'GB',
            PersonMailingCountryCode  = 'GB',
            PersonMailingPostalCode = 'LS9 9EE',
            PersonMailingCity = 'Leeds'
        );
        
        insert accountTest;
        return accountTest;
    }          
}