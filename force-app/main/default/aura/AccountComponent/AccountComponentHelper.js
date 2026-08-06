({
    
    retrievePageLayoutFields : function(cmp, hlpr){
        // Retorna el JSON con la estructura del layout
        if(cmp.isValid()){
            // Cambio 21/08/19: Se le pasa el record type id para el cambio de record type. 
            // Si este es nulo se toma el record type id de la cuenta.
            var action = cmp.get("c.getPageLayoutFields");
            action.setParams({
                recordId : cmp.get("v.recordId"),
                recordTypeId : cmp.get("v.recordTypeId")
            });
            
            action.setCallback(this, function(response) {
                
                var state = response.getState();
                var serverResponse = response.getReturnValue();
                
                if(state === "SUCCESS"){
                    
                    window.setTimeout(
                        $A.getCallback(function() {
                            cmp.set("v.spinner", false);
                        }), 1000
                    );
                    
                    //console.log('original serverResponse:' + JSON.stringify(serverResponse));
                    
                    serverResponse.forEach(function (arrayItem) {
                        
                        if(!$A.util.isEmpty(arrayItem.fieldList)){
                            
                            //console.log(arrayItem.label);
                            var customLabel = arrayItem.label.split(' ').join('_');
                            arrayItem.label = customLabel;
                            //console.log('customLabel ' + customLabel);
                            
                            var attributeString = 'v.' + customLabel;     
                            //console.log(attributeString);
                            cmp.set(attributeString, $A.getReference("$Label.c." + customLabel));
                            
                        }
                        
                    });
                    
                    //console.log('converted serverResponse:' + JSON.stringify(serverResponse));
                    cmp.set("v.layoutSections", serverResponse);
                    
                }
                
                else if(state === "INCOMPLETE"){                    
                    console.log("STATUS INCOMPLETE");                    
                }              
                    else if(state === "ERROR"){                        
                        var errors = response.getError();
                        console.log( errors );
                        
                    }
                
            });
            
            $A.enqueueAction(action);
        }
    },
    
    updateAccount : function(cmp, hlpr, jsonObject, nameChanged){
        console.log('Name Changed: ' + nameChanged);
        var action = cmp.get("c.saveAccount");
        var recordId = cmp.get("v.recordId");
        action.setParams({
            jsonString : JSON.stringify(jsonObject),
            recordId : recordId,
            nameChanged : nameChanged
        });
        
        cmp.set("v.spinnerSaving", true);
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            cmp.set("v.spinnerSaving", false);
            cmp.set("v.stopReload", true);
            
            if(state === "SUCCESS"){
                
                //console.log("Success: " + JSON.stringify(serverResponse));
                
                if( serverResponse !== null && serverResponse === Object(serverResponse) ){
                    // Estiliza el toast de Respuesta de guardado segun el json que retorna el metodo.
                    var type = serverResponse.success ? "success" : "error";
                    var title = serverResponse.success ? $A.get("$Label.c.Success") + "!" : serverResponse.errorTitle;
                    var duration = serverResponse.success ? 5000 : 10000;
                    var message = serverResponse.success ? $A.get("$Label.c.Account_SAP_details_saved") : serverResponse.errorMessage;
                    
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": title,
                        "type": type,
                        "message": message,
                        "mode": serverResponse.success ? 'dismissible' : 'sticky'
                    });
                    
                    toastEvent.fire();
                    
                    // Si todo salio bien cierra el formulario, sino lo deja abierto.
                    if(serverResponse.success){
                    	hlpr.navigateToRecord(cmp, cmp.get("v.recordId"));    
                    }
                    
                }
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
            else if(state === "ERROR"){
                    
                var errors = response.getError();
                console.log( errors );
                
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "type": "error",
                    "mode": 'sticky',
                    "message": JSON.stringify(errors)
                });
                toastEvent.fire();
                
                //hlpr.navigateToRecord(cmp, cmp.get("v.recordId"));
            }
            
        });
        
        $A.enqueueAction(action);
        
    },
    
    highlightRequiredFields : function(cmp, inputField, inputFieldName, hasError){
        // Si el component tiene un error entonces lo pinta de rojo y muestra un mensaje.
        // Sino, los oculta.
        let element = document.getElementById(inputFieldName);
        
        if(hasError){
        
            element.classList.remove("slds-hide");
            $A.util.addClass(inputField, 'slds-has-error');
        } else {
        
            element.classList.add("slds-hide");
            $A.util.removeClass(inputField, 'slds-has-error');
        }
        
    },
    
    setRequiredList : function (cmp){
        // Recorre el objecto del layout y forma una lista con todos los nombres de los campos
        // que tienen el atributo required.
        var layoutSections = cmp.get("v.layoutSections");
        var requiredList = [];
        
        if(layoutSections != undefined){
            for(let i = 0; i < layoutSections.length; i++){
                
                let fieldList = layoutSections[i].fieldList;
                
                for(let j=0; j < fieldList.length; j++){
                    let field = fieldList[j];
                    
                    if(field.isRequired){
                        requiredList.push(field.fieldName);
                        console.log("required: " + field.fieldName);
                    }
                }
            }
        }
        
        cmp.set("v.requiredList", requiredList);
    },
    
    navigateToRecord : function(cmp, recordId){
		// Navega hasta la pagina del registro que esta siendo editado.
        var navService = cmp.find("navService");
        
        if(navService != undefined){
            
            var pageReference = {
                "type": 'standard__recordPage',
                "attributes": {
                    "recordId": recordId,
                    "objectApiName": 'Account',
                    "actionName": 'view'
                }
            };
            // Manda un refresco de pantalla a ejecutarse despues de que se cierre el formulario
            // Esto es para que los cambios se vean reflejados automaticamente en pantalla.            
            window.setTimeout($A.getCallback(function(){
                $A.get('e.force:refreshView').fire();
                console.log("refreshed");
            }),10);
            
            navService.navigate(pageReference, true);
            
        }
        
    },
    
    isInputInvalid : function(cmp, inputValue){
        // Verifica que un valor no sea nulo
        return (inputValue == null || inputValue == "" || inputValue == undefined);
    },
    
    isCompoundField : function(cmp, fieldValue){
        // Verifica si el campo es compuesto. Checkeando si su valor es un objecto.
        return fieldValue !== null && fieldValue === Object(fieldValue);
    },
    
    checkUserHasAccess : function(cmp, hlpr){
        
        var action = cmp.get("c.userHasAccess");
        var recordId = cmp.get("v.recordId");
        
        action.setParams({
            recordId : recordId
        });
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            console.log("serverResponse: " + JSON.stringify(serverResponse));
            
            if(state === "SUCCESS"){
                cmp.set("v.userHasAccess", serverResponse.hasAccess);
                cmp.set("v.userIsAdmin", serverResponse.isAdmin);
                cmp.set("v.userHasSap", serverResponse.userHasSap);
                cmp.set("v.accountOnSap", serverResponse.accountOnSap);
                cmp.set("v.canEditSapData", serverResponse.canEditSAPData);
                
                if(serverResponse.hasAccess == false){
                    cmp.set("v.errorTitle", $A.get("$Label.c.Insufficient_Permissions_Error"));
                    cmp.set("v.errorMessage", $A.get("$Label.c.AccCMP_Permission"));
                    cmp.set("v.displayWarningMessage", true);
                }
                if(serverResponse.userHasSap == false && serverResponse.accountOnSap == true){
                    cmp.set("v.errorTitle", $A.get("$Label.c.Insufficient_Permissions_Error"));
                    cmp.set("v.errorMessage", $A.get("$Label.c.Account_no_editable_context"));
                    cmp.set("v.displayWarningMessage", true);
                }
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
            else if(state === "ERROR"){
                    
                var errors = response.getError();
                console.log( errors );
                
                cmp.find("notificationsLibrary").showNotice({
                    "variant": "error",
                    "header": "Error",
                    "title": 'Error',
                    "message": 'Error retrieving data.',
                    closeCallback: function() {
                        
                    }
                });
            }
            
        });
        
        $A.enqueueAction(action);
        
    },
    
})