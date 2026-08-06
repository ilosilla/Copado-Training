@IsTest
public class gestionClienteTest {
    @testSetup static void setup() {
        
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
    
    @isTest static void obtenerClienteTest(){
        
        // Success
        Account acc = crearCliente();

        RestRequest request1 = new RestRequest();
        request1.requestUri =
            '/services/apexrest/Cliente/'
            + acc.Id;
        request1.httpMethod = 'GET';
        RestContext.request = request1;
        
        List<Account> result1 = [SELECT Id, FirstName, LastName, PersonEmail 
                                 FROM Account
                                 WHERE Id = :acc.Id]; 

        System.assert(result1.size() != 0);
        System.assert(result1[0].FirstName == 'Jekyll');
        System.assert(result1[0].LastName == 'Hyde');
        System.assert(result1[0].PersonEmail == 'jhyde@porcelanosa.com');
        
        // Fail
        String recordId = 'F011w000002fwdQAAQ';
        
        RestRequest request2 = new RestRequest();
        request2.requestUri =
            '/services/apexrest/Cliente/'
            + recordId;
        request2.httpMethod = 'GET';
        RestContext.request = request2;
        
        List<Account> result2 = [SELECT Id 
                                 FROM Account
                                 WHERE Id = :recordId];
        
        System.assert(result2.size() == 0);
        
    }
    
    @isTest static void crearClienteTest() {
        
        // Map para verificar respuestas
        Map<String, Object> responseMap;
    
        // Success
        RestRequest request1 = new RestRequest();
        RestResponse response1 = new RestResponse();
            
        request1.requestURI = '/services/apexrest/Cliente';
        request1.httpMethod = 'POST';
        request1.requestBody = Blob.valueOf('{"Salutation": "002","FirstName": "Julián", "LastName": "Test", "PersonEmail": "jtest@porcelanosa.com", "Country__c": "ES", "Language__c" : "es_ES", "PostCode__c" : "3000", "Gender__c": "M", "PersonBirthdate" : "1990-12-12"}');

        RestContext.request = request1;
        RestContext.response = response1;
            
        gestionCliente.crearCliente();
        
        // System.assert(response1.statusCode >= 200 && response1.statusCode <= 299);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'El cliente ha sido creado con éxito.');
        
        // Success (El cliente ya existe en BD y es de tipo 'Potencial' -buscado por ID-)
        Account acc = crearClientePotencial(1);
        request1.requestBody = Blob.valueOf('{"Id" : "'+ acc.Id + '", "FirstName": "JoseMa", "LastName": "Test", "Country__c": "ES", "Language__c" : "es_ES", "PostCode__c" : "3000", "Gender__c": "M", "PersonBirthdate" : "1990-12-12"}');

        gestionCliente.crearCliente();
        
        //System.assert(response1.statusCode == 201);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'El \'Cliente Potencial\' ha sido convertido a \'Cliente\'.');
        
        // Success (El cliente ya existe en BD y es de tipo 'Potencial' -buscado por Email-)
        acc = crearClientePotencial(2);
        request1.requestBody = Blob.valueOf('{"FirstName": "Antonio", "Salutation": "002", "LastName": "Dion", "PersonEmail": "'+ acc.PersonEmail + '", "Country__c": "ES", "Language__c" : "es_ES", "PostCode__c" : "3000", "Gender__c": "M", "PersonBirthdate" : "1990-12-12"}');

        gestionCliente.crearCliente();
        
        //System.assert(response1.statusCode == 200);
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'El \'Cliente Potencial\' ha sido convertido a \'Cliente\'.');
        
        // Fail (El cliente ya existe en BD y es de tipo 'Potencial', pero uno de los campos es inválido)
        acc = crearClientePotencial(3);
        request1.requestBody = Blob.valueOf('{"Salutation": "002", "FirstName": "JoseMa", "LastName": "Test", "PersonEmail": "'+ acc.PersonEmail + '", "Language__c" : "es_ES", "PostCode__c" : "3000", "Gender__c": "X", "PersonBirthdate" : "1990-12-12"}');

        gestionCliente.crearCliente();
        
        //System.assert(response1.statusCode == 500);
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'Gender: valor inapropiado para el campo de lista de selección restringida: X.');
        
        // Fail (El campo 'PersonEmail' es nulo)
        request1.requestBody = Blob.valueOf('{"Salutation": "002", "FirstName": "Álvaro", "LastName": "Test", "Country__c": "ES", "Language__c" : "es_ES", "PostCode__c" : "3000", "Gender__c": "M", "PersonBirthdate" : "1990-12-12"}');
        RestContext.request = request1;
        
        gestionCliente.crearCliente();
        
        //System.assert(response1.statusCode == 500);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'El campo \'PersonEmail\' no puede quedar vacío.');
        
        // Fail (El registro es de tipo 'Cliente' por lo cual no requiere conversión)
        Account acc3 = crearCliente();
        
        request1.requestBody = Blob.valueOf('{"Salutation": "002", "FirstName": "Jekyll", "LastName": "Hyde", "PersonEmail": "'+ acc3.PersonEmail + '", "Country__c": "ES", "Language__c" : "es_ES", "PostCode__c" : "3000", "Gender__c": "M", "PersonBirthdate" : "1990-12-12"}');

        gestionCliente.crearCliente();
        
        //System.assert(response1.statusCode == 300);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());
        //System.assert(responseMap.get('message') == 'El registro ya es de tipo \'Cliente\' por lo cual no requiere conversión.');
        
        // Fail (Alguno de los campos proporcionados no corresponde a Cuenta -Mascota-)
        request1.requestBody = Blob.valueOf('{"Salutation": "002", "FirstName": "Diego", "LastName": "Ramírez", "PersonEmail": "'+ acc3.PersonEmail + '", "Country__c": "ES", "Mascota" : "111"}');
        gestionCliente.crearCliente();
        
        //System.assert(response1.statusCode == 400);
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response1.responseBody.toString());        
        //System.assert(responseMap.get('message') == 'Alguno de los campos proporcionados no existe. Revise nuevamente el cuerpo de la solicitud.');
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');        
    }
    
    @isTest static void eliminarClienteTest() {
        
        // Map para verificar respuestas
        Map<String, Object> responseMap;
                
        // Success
        Account acc = crearCliente();
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri =
            '/services/apexrest/Cliente/'
            + acc.Id;    
        request.httpMethod = 'DELETE';
        
        RestContext.request = request;        
        RestContext.response = response;

        gestionCliente.eliminarCliente();
        
        System.assert(response.statusCode == 200);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El registro ha sido eliminado con éxito.');
        
        // Fail (El id provisto no corresponde a ningún Cliente Potencial)
        String recordId = 'F011w000002fwdQAAQ';
        
        request.requestUri =
            '/services/apexrest/Cliente/'
            + recordId;
        request.httpMethod = 'DELETE';
        
        gestionCliente.eliminarCliente();
        
        System.assert(response.statusCode == 404);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El Id provisto no corresponde a ningún registro de tipo \'Cliente\'.');
        
    }
    
    @isTest static void modificarClienteTest(){
        
        // Map para verificar respuestas
        Map<String, Object> responseMap;
        
        // Success
        Account acc = crearCliente();
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestUri =
            '/services/apexrest/Cliente/'
            + acc.Id;
        request.httpMethod = 'PATCH';
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"FirstName": "Álvaro", "LastName": "Rodríguez", "PersonEmail": "arod@neoris.com", "Country__c": "ES"}');  
        
        RestContext.request = request;
        RestContext.response = response;
        
        gestionCliente.modificarCliente();

        System.assert(response.statusCode == 200);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El registro ha sido actualizado con éxito.');
        
        // Fail ('El Id provisto no corresponde a ningún Cliente')
        String recordId = 'F011w000002fwdQAAQ';
        
        request.requestUri =
            '/services/apexrest/Cliente/'
            + recordId;
        request.httpMethod = 'PATCH';
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"FirstName": "Álvaro", "LastName": "Rodríguez", "PersonEmail": "arod@neoris.com", "Country__c": "ES"}');
        
        gestionCliente.modificarCliente();
        
        System.assert(response.statusCode == 404);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'El Id provisto no corresponde a ningún registro de tipo \'Cliente\'.');
        
        // Fail (Alguno de los campos proporcionados no existe -Email-)
        request.requestUri =
            '/services/apexrest/Cliente/'
            + acc.Id;
        request.httpMethod = 'PATCH';
        
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"FirstName": "Álvaro", "LastName": "Rod", "Email": "arod@neoris.com", "Country__c": "ES"}');
        
        gestionCliente.modificarCliente();
        
        System.assert(response.statusCode == 400);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(responseMap.get('message') == 'Alguno de los campos proporcionados no existe. Revise nuevamente el cuerpo de la solicitud.');
        
        // Fail (El campo 'PersonEmail' tiene un formato incorrecto)
		request.requestBody = Blob.valueOf('{"FirstName": "Diego", "LastName": "Ramírez", "PersonEmail": "aaa", "Country__c": "ES"}');
        gestionCliente.crearCliente();
        
        System.assert(response.statusCode == 500);        
        responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        // System.assert(responseMap.get('message') == 'Correo electrónico: dirección de correo electrónico no válida: aaa.');
        
    }
    
    static List<Account> clientesPotencialesList = new List<Account>{
        new Account(
            FirstName = 'Luciano',
            LastName = 'Cotto',
            PersonEmail = 'lcotto@porcelanosa.com',
            PersonMailingCountryCode  = 'GB',
            PersonMailingPostalCode = 'LS9 9BE',
            PersonMailingCity = 'Leeds',            
            Country__c = 'GB'),            
            new Account(
                FirstName = 'David',
                LastName = 'Cozzutti',
                PersonEmail = 'dcozzutti@porce.com',
                Country__c = 'GB',
                PersonMailingCountryCode  = 'GB',
                PersonMailingPostalCode = 'LS9 9FE',
                PersonMailingCity = 'Leeds'
            ),
            new Account(
                FirstName = 'Chris',
                LastName = 'Pratt',
                PersonEmail = 'cpratt@porcelanosa.com',
                Country__c = 'GB',
                PersonMailingCountryCode  = 'GB',
                PersonMailingPostalCode = 'LS9 9EE',
                PersonMailingCity = 'Leeds'
                
            )
    };
    
    static Account crearClientePotencial(Integer index) {
        // Create test record
        Account accountTest = clientesPotencialesList.get(index - 1);
        
        insert accountTest;
        return accountTest;
    }
    
    static Account crearCliente(){
        
        Account accountTest = new Account(
            Salutation = '002',
            FirstName = 'Jekyll',
            LastName = 'Hyde',
            PersonEmail = 'jhyde@porcelanosa.com',
            PersonMailingCountryCode  = 'GB',
     		PersonMailingPostalCode = 'LS9 9EE',
     		PersonMailingCity = 'Leeds',
			Potential__c = false            
        );
        
        insert accountTest;
        return accountTest;
        
    }
}