@RestResource(urlMapping='/Cliente/*')
global with sharing class gestionCliente {
    
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
    global static void obtenerCliente() {
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;
        
        RestResponse response = RestContext.response;
        
        RestRequest request = RestContext.request;
        // Obtener el ID de Account de la última parte de la URL
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        
        List<Account> result =  [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c, ConversionDate__c, Postcode__c, company_list__c, 
                                 Address__c, Town__c, Province__c, Gender__c, PersonBirthdate, PersonMobilePhone, Phone, BillingStreet, BillingCity, BillingState, 
                                 BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Source__c, Label__c
                                 FROM Account
                                 WHERE Id = :accountId];
        
        if(result != null && !result.isEmpty()){
            
            myMap.put('record', result[0]);
            myMap.put('message', 'El registro ha sido encontrado.');			
			jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
        else{
            
            myMap.put('record', null);
            myMap.put('message', 'El Id provisto no corresponde a ningún registro de tipo \'Cliente\'.');			
			jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 404;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
    }
    
    @HttpPost
    global static void crearCliente(){
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;
        
        RestResponse response = RestContext.response;
        
        RestRequest request = RestContext.request;
        Map<String, Object> reqMap = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        // Set para almacenar todos los campos del objeto Account
        Set<String> accountFields = Schema.SObjectType.Account.fields.getMap().keySet(); 
        Boolean doesntExistError = false;
        
        for(String fieldName : reqMap.keySet()) {
            // Verifica que los campos proporcionados pertenecen al objeto Account
            if(!accountFields.contains(fieldName.toLowerCase())){                
                doesntExistError = true;                
            }            
        }
        
        if(!doesntExistError){
            
            // Map para obtener los campos que hay que "actualizar"
            Map<String,String> fieldMap = getFieldsToSave(reqMap);
            
            List<Account> result;
            
            if(fieldMap.get('Id') != null){
                
                result = [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c, ConversionDate__c, Postcode__c, company_list__c, 
                          Address__c, Town__c, Province__c, Gender__c, PersonBirthdate, PersonMobilePhone, Phone, BillingStreet, BillingCity, BillingState, 
                          BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Source__c, Label__c
                          FROM Account
                          WHERE Id = :fieldMap.get('Id') LIMIT 1];
                
            }
            // Si el ID no existe, se realiza la consulta por email
            else{
                
                result = [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c, ConversionDate__c, Postcode__c, company_list__c, 
                          Address__c, Town__c, Province__c, Gender__c, PersonBirthdate, PersonMobilePhone, Phone, BillingStreet, BillingCity, BillingState, 
                          BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Source__c, Label__c
                          FROM Account
                          WHERE PersonEmail = :fieldMap.get('PersonEmail') LIMIT 1];
                
            }
            
            if(result != null && !result.isEmpty()){
                
                // verificar si el cliente es de tipo Potencial (para proceder a la conversión)
                if(result[0].Potential__c == True && result[0].ConversionDate__c == null){
                    
                    result[0].Potential__c = False;
                    result[0].ConversionDate__c = System.today();
                    result[0].RecordTypeId = customerRecordTypeId;
                    
                    for(String fieldName : fieldMap.keySet()){
                        
                        if(fieldName != 'FirstName' && fieldName != 'LastName' && fieldName != 'PersonEmail' && fieldName != 'Country__c' && fieldName != 'Language__c' && fieldName != 'Potential__c'){
                            
                            if(fieldName == 'PersonBirthdate'){result[0].put(fieldName,Date.valueOf(fieldMap.get(fieldName)));}
                            else if(fieldName == 'BillingCountry' || fieldName == 'ShippingCountry'){result[0].put(fieldName,fieldMap.get(fieldName).toUpperCase());}
                            else if(fieldName == 'Address__c'){result[0].put(fieldName,formatAddress(fieldMap.get(fieldName)));}
                            else {result[0].put(fieldName, fieldMap.get(fieldName));}
                            
                        }
                    }
                    
                    try{
                        
                        update result[0];
                        
                        // para que el JSON de retorno no devuelva la dirección con \n
                        result[0].Address__c = fieldMap.get('Address__c');
                        
                        myMap.put('record', result[0]);
                        myMap.put('message', 'El \'Cliente Potencial\' ha sido convertido a \'Cliente\'.');                        
                        jsonStr = JSON.serialize(myMap);
                        
                        response.statusCode = 200;
                        response.responseBody = Blob.valueOf(jsonStr);
                        
                    }catch (System.DmlException e){
                        
                        myMap.put('record', null);
                        myMap.put('message', e.getDmlMessage(0) + '.');
                        jsonStr = JSON.serialize(myMap);
                        
                        response.statusCode = 500;
                        response.responseBody = Blob.valueOf(jsonStr);
                        
                    }
                    
                }
                // Caso contrario, el registro ya es de tipo 'Cliente'
                else{
                    
                    myMap.put('record', result[0]); 
                    myMap.put('message', 'El registro ya es de tipo \'Cliente\' por lo cual no requiere conversión.');                  
                    jsonStr = JSON.serialize(myMap);
                    
                    response.statusCode = 300;
                    response.responseBody = Blob.valueOf(jsonStr);
                    
                }
                
            }
            // Si el registro no existe, se procede a la creación del mismo
            else{
                
                Account newAccount = new Account(
                    FirstName = fieldMap.get('FirstName'), 
                    LastName = fieldMap.get('LastName'),
                    PersonEmail = fieldMap.get('PersonEmail'),
                    Country__c = fieldMap.get('Country__c').toUpperCase(),
                    Potential__c = False,
                    RecordTypeId = customerRecordTypeId
                );
                
                try {
                    
                    insert newAccount;
                    
                    for(String fieldName : fieldMap.keySet()){
                        
                        if(fieldName != 'FirstName' && fieldName != 'LastName' && fieldName != 'PersonEmail' && fieldName != 'Country__c' && fieldName != 'Language__c' && fieldName != 'Potential__c'){
                            
                            if(fieldName == 'PersonBirthdate'){newAccount.put(fieldName,Date.valueOf(fieldMap.get(fieldName)));}
                            else if(fieldName == 'BillingCountry' || fieldName == 'ShippingCountry'){newAccount.put(fieldName,fieldMap.get(fieldName).toUpperCase());}
                            else if(fieldName == 'Address__c'){newAccount.put(fieldName,formatAddress(fieldMap.get(fieldName)));}
                            else {newAccount.put(fieldName, fieldMap.get(fieldName));}
                            
                        }
                        
                    }
                    
                    update newAccount;
                    
                    // para que el JSON de retorno no devuelva la dirección con \n
                    newAccount.Address__c = fieldMap.get('Address__c');
                    
                    myMap.put('record', newAccount);
                    myMap.put('message', 'El cliente ha sido creado con éxito.');
                    jsonStr = JSON.serialize(myMap);
                    
                    response.statusCode = 201;
                    response.responseBody = Blob.valueOf(jsonStr);
                    
                } catch (System.DmlException e) {
                    
                    if(newAccount.Id != null) {delete newAccount;}
                    
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
            myMap.put('message', 'Alguno de los campos proporcionados no existe. Revise nuevamente el cuerpo de la solicitud.');
            jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(jsonStr);
            
        }
        
    }
    
    @HttpDelete
    global static void eliminarCliente(){
        
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
            myMap.put('message', 'El Id provisto no corresponde a ningún registro de tipo \'Cliente\'.');                
            jsonStr = JSON.serialize(myMap);
            
            response.statusCode = 404;
            response.responseBody = Blob.valueOf(jsonStr);

        }
        
    }
    
    @HttpPatch
    global static void modificarCliente() {
        
        // Map para personalizar respuesta
        Map<String, Object> myMap = new Map<String, Object>();
        String jsonStr;
        
        RestResponse response = RestContext.response;
        
        RestRequest request = RestContext.request;
        // Obtener el ID de Account de la última parte de la URL
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        
        List<Account> result = [SELECT FirstName, LastName, PersonEmail, Country__c, Language__c, Potential__c, ConversionDate__c, Postcode__c, company_list__c,
                                Address__c, Town__c, Province__c, Gender__c, PersonBirthdate, PersonMobilePhone, Phone, BillingStreet, BillingCity, BillingState, 
                                BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Source__c, Label__c
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
                    
                    // Si el campo es 'Country__c', se actualizan los valores a mayúsculas (en caso de que se introduzcan minúsculas)
                    if(fieldName == 'Country__c' && params.get(fieldName) != null){
                        
                        String myCountry = params.get(fieldName).toString().toUpperCase();
                        result[0].put(fieldName, myCountry);
                        
                    }
                    
                    else{
                        
                        if(fieldName == 'PersonBirthdate'){result[0].put(fieldName, Date.valueOf(params.get(fieldName).toString()));}
                        else if(fieldName == 'Address__c'){result[0].put(fieldName,formatAddress(params.get(fieldName).toString()));}
                        else{result[0].put(fieldName, params.get(fieldName));}
                        
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
                    
                    // para que el JSON de retorno no devuelva la dirección con \n
                    if(params.get('Address__c') != null) {result[0].Address__c = params.get('Address__c').toString();}
                    
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
                myMap.put('message', 'Alguno de los campos proporcionados no existe. Revise nuevamente el cuerpo de la solicitud.');                                      
                jsonStr = JSON.serialize(myMap);
                
                response.statusCode = 400;		
                response.responseBody = Blob.valueOf(jsonStr);
                
            }
            
        }
        
        else{
            
            myMap.put('record', null);
            myMap.put('message', 'El Id provisto no corresponde a ningún registro de tipo \'Cliente\'.');                                      
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
    
    static String formatAddress(String address){
        
		List<String> addressList = address.split(',');
        String formattedAddress = String.format('{0}\n{1}\n{2}\n{3}',addressList);
        
        if(addressList.size() < 4){
            
            formattedAddress = formattedAddress.substringBefore('{');
        
        }
        
        return formattedAddress;
        
    }
    
}