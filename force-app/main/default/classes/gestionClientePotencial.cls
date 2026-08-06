@RestResource(urlMapping='/ClientePotencial/*')
global with sharing class gestionClientePotencial {
    
    public static Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
    // Lista de Países que permitirán obtener el idioma (debería ampliarse)
    public static Map<String, String> countryMap = new Map<String, String>{
                'ES' => 'es_ES',
                'US' => 'en_US',
                'GB' => 'en_GB',
                'FR' => 'fr_FR',
                'PT' => 'pt_PT'
    };
    
    @HttpGet
    global static void obtenerClientePotencial() {
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;
        
        RestResponse response = RestContext.response;
        
        RestRequest request = RestContext.request;
        // Obtener el ID de Account de la última parte de la URL
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        
        List<Account> result =  [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c
                                 FROM Account
                                 WHERE Id = :accountId];
        
        if(result != null && !result.isEmpty()){
            
            myMap.put('record', result[0]);
            myMap.put('message','El registro ha sido encontrado.');
			jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
        else{
            
            myMap.put('record', null);
            myMap.put('message', 'El Id provisto no corresponde a ningún registro de tipo \'Cliente potencial\'.');			
			jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 404;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
    }
    
    @HttpPost
    global static void crearClientePotencial() {
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;
        
        RestResponse response = RestContext.response; 
        
        RestRequest request = RestContext.request;
        Map<String, Object> reqMap = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        // Set para almacenar todos los campos del objeto Account
        Set<String> accountFields = Schema.SObjectType.Account.fields.getMap().keySet(); 
        Boolean forbiddenField = false;
        
        for(String fieldName : reqMap.keySet()) {
            // Verifica que los campos proporcionados pertenecen al objeto Account
            if(!accountFields.contains(fieldName.toLowerCase()) || (fieldName != 'FirstName' && fieldName != 'LastName' && fieldName != 'PersonEmail' && fieldName != 'Country__c' && fieldName != 'Language__c')){                
                forbiddenField = true;                
            }            
        }
        
        if(!forbiddenField){
            
            // Map para obtener los campos que hay que "actualizar"
            Map<String,String> fieldMap = getFieldsToSave(reqMap);
            
            if(fieldMap.get('PersonEmail') != null){
                
                List<Account> result = [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c
                                        FROM Account
                                        WHERE PersonEmail = :fieldMap.get('PersonEmail') LIMIT 1];
                
                if(result != null && !result.isEmpty()) {
                    
                    myMap.put('record', result[0]);
                    myMap.put('message', 'Ya existe una cuenta con dicho email en BD.');
                    jsonStr = JSON.serialize(myMap);
                    
                    response.statusCode = 300;
                    response.responseBody = Blob.valueOf(jsonStr);
                    
                }
                
                else if (result == null || result.isEmpty()) {
                    
                    Account newAccount = new Account(
                        FirstName = fieldMap.get('FirstName'),
                        LastName = fieldMap.get('LastName'),
                        PersonEmail = fieldMap.get('PersonEmail'),
                        Country__c = fieldMap.get('Country__c').toUpperCase(),
                        Language__c = fieldMap.get('Language__c'),
                        Potential__c = True,
                        RecordTypeId = customerRecordTypeId
                    );
                    
                    try {
                        
                        insert newAccount;
                        
                        myMap.put('record', newAccount);
                        myMap.put('message', 'El cliente potencial ha sido creado con éxito.');
                        jsonStr = JSON.serialize(myMap);
                        
                        response.statusCode = 201;
                        response.responseBody = Blob.valueOf(jsonStr);
                        
                    } catch (System.DmlException e) {
                        
                        myMap.put('record', null);
                        myMap.put('message', e.getDmlMessage(0) + '.');
                        jsonStr = JSON.serialize(myMap);
                        
                        response.statusCode = 500;
                        response.responseBody = Blob.valueOf(jsonStr);
                        
                    }
                    
                }
                
            }
            
            else{
                
                myMap.put('record', null);
                myMap.put('message', 'Faltan campos obligatorios: [PersonEmail]');
                jsonStr = JSON.serialize(myMap);
                
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(jsonStr);
                
            }
            
        }
        
        else{
            
            myMap.put('record', null);
            myMap.put('message', 'Alguno de los campos proporcionados no existe o no corresponde a Cliente Potencial. Revise nuevamente el cuerpo de la solicitud.');
            jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 400;		
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
    }
    
    @HttpDelete
    global static void eliminarClientePotencial(){
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;
        
        RestResponse response = RestContext.response;
        
        RestRequest request = RestContext.request;
        // Obtener el ID de Account de la última parte de la URL
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        
        List<Account> result= [SELECT Id
                               FROM Account 
                               WHERE Id = :accountId];
        
        if(result != null && !result.isEmpty()){
            
            try {
                
                delete result[0];
                
                myMap.put('record', null);
                myMap.put('message', 'El registro ha sido eliminado con éxito.');                
                jsonStr = JSON.serialize(myMap);
                
                response.statusCode = 200;
                response.responseBody = Blob.valueOf(jsonStr);
                
            } catch (System.DmlException e) {
                
                myMap.put('record', null);
                myMap.put('message', e.getDmlMessage(0) + '.');                
                jsonStr = JSON.serialize(myMap);
                
                response.statusCode = 500;
                response.responseBody = Blob.valueOf(jsonStr);
                
            }
            
        }
        
        else{
            
            myMap.put('record', null);
            myMap.put('message', 'El Id provisto no corresponde a ningún registro de tipo \'Cliente potencial\'.');                
            jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 404;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
    }
    
    @HttpPatch
    global static void modificarClientePotencial() {
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;

        RestResponse response = RestContext.response;
        
        RestRequest request = RestContext.request;
        // Obtener el ID de Account de la última parte de la URL
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        
        List<Account> result = [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c
                                FROM Account
                                WHERE Id = :accountId];   
        
        if(result != null && !result.isEmpty()){
            
            // Set para almacenar todos los campos del objeto Account
            Set<String> accountFields = Schema.SObjectType.Account.fields.getMap().keySet(); 
            Boolean doesntExistError = false;
            
            Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
            // Itera sobre cada campo y valor del mapa para actualizar los campos correspondientes
            for(String fieldName : params.keySet()) {
                // Verifica que los campos proporcionados pertenecen al objeto Account
                if(accountFields.contains(fieldName.toLowerCase())){
                    // Modifica los campos del registro Account sólo si corresponde a los propios de Clientes Potenciales
                    if(fieldName == 'FirstName' || fieldName == 'LastName' || fieldName == 'PersonEmail' || fieldName == 'Country__c' || fieldName == 'Language__c'){
                        
                        // Si el campo es 'Country__c', se actualizan los valores a mayúsculas (en caso de que se introduzcan minúsculas)
                        if(fieldName == 'Country__c' && params.get(fieldName) != null){
                            
                            String myCountry = params.get(fieldName).toString().toUpperCase();
                            result[0].put(fieldName, myCountry);
                            
                        }
                        
                        else{
                            
                            if(fieldName == 'LastName' && (params.get(fieldName) == null || String.isEmpty(params.get(fieldName).toString()))){result[0].put(fieldName, 'NA');}
                            else{result[0].put(fieldName, params.get(fieldName));}
                            
                        }
                        
                    }
                    
                    else{
                        // Si algún campo no corresponde a Cliente Potencial, arrojará mensaje de error
                        doesntExistError = true;
                    
                    }
                    
                }
                // Si algún campo no existe, arrojará mensaje de error
                else{
                    
                    doesntExistError = true;
                    
                }
                
            }
            
            if(!doesntExistError){
                
                try {
                    
                    update result[0];
                    
                    myMap.put('record', result[0]);
                    myMap.put('message', 'El registro ha sido actualizado con éxito.');                                      
                    jsonStr = JSON.serialize(myMap);
                    
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(jsonStr);
                    
                } catch (System.DmlException e) {
                    
                    myMap.put('record', null);
                    myMap.put('message', e.getDmlMessage(0) + '.');                                      
                    jsonStr = JSON.serialize(myMap);
                    
                    response.statusCode = 500;
                    response.responseBody = Blob.valueOf(jsonStr);
                    
                }
                
            }
            
            else{
                
                myMap.put('record', null);
                myMap.put('message', 'Alguno de los campos proporcionados no existe o no corresponde a Cliente Potencial. Revise nuevamente el cuerpo de la solicitud.');                                      
                jsonStr = JSON.serialize(myMap);
                
                response.statusCode = 400;		
                response.responseBody = Blob.valueOf(jsonStr);
                
            }
            
        }
        
        else{
            
            myMap.put('record', null);
            myMap.put('message', 'El Id provisto no corresponde a ningún registro de tipo \'Cliente potencial\'.');                                      
            jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 404;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
    }
        
    static Map<String,String> getFieldsToSave(Map<String, Object> reqMap){
            
            Map<String,String> fieldsToSave = new Map<String,String>();
            
            for(String fieldName : reqMap.keySet()) {
                
                if(reqMap.get(fieldName) != null){fieldsToSave.put(fieldName, reqMap.get(fieldName).toString());}
                
            }
            
            return fieldsToSave;
            
   }
    
}