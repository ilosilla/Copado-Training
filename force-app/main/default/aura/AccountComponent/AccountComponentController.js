({
    
    doInit: function(cmp, evt, hlpr) {        
        cmp.set("v.headerTitle", ($A.util.isUndefined(cmp.get("v.recordId")) ? '' : $A.get("$Label.c.Edit_Account")));
        hlpr.checkUserHasAccess(cmp, hlpr);
        var state = cmp.get("v.pageReference").state; 
        if(state.hasOwnProperty("recordTypeId")){
            cmp.set("v.recordTypeId", state.recordTypeId);
            cmp.set("v.isRecTypeChange", true);
        }
        cmp.set("v.ready", true);
    },
    
    setMode : function(cmp, evt, hlpr){   
        if(!cmp.get("v.stopReload") && cmp.get("v.recordId") != null){
            // stopReload es para que setMode no se dispare si el componente tarda en cerrarse luego de guardar cambios.
            var currentRecordObject = cmp.get("v.currentRecordObject");            
            hlpr.retrievePageLayoutFields(cmp);  
        }
    },

    closeComponent : function(cmp, evt, hlpr) {
        hlpr.navigateToRecord(cmp, cmp.get("v.recordId"));
    },

    handleOnload : function(cmp, evt, hlpr){
        if(cmp.isValid() && !cmp.get("v.stopReload")){
            // Crea una lista con los campos que son requeridos.

            hlpr.setRequiredList(cmp);
            
            var inputFieldList = cmp.find("inputField");
            var requiredList = cmp.get("v.requiredList");
            var currentRecordObject = cmp.get("v.currentRecordObject");
            
            if(inputFieldList != undefined && requiredList != undefined){
                if(!Array.isArray(inputFieldList)){
                    inputFieldList = [inputFieldList];
                }
                for(var x in inputFieldList){
                    
                    if(inputFieldList[x] != undefined && $A.util.isObject(inputFieldList[x]) && !$A.util.isEmpty(inputFieldList[x])){ //  
                        
                        let inputFieldName = inputFieldList[x].get("v.fieldName");
                        let inputFieldValue = inputFieldList[x].get("v.value");
                        
                        // Workaround para personAccount
                        if(currentRecordObject.IsPersonAccount && inputFieldName == "Name" && inputFieldValue != undefined ){
                            cmp.set("v.firstName", inputFieldValue.FirstName );
                            cmp.set("v.lastName", inputFieldValue.LastName );
                            cmp.set("v.salutation", inputFieldValue.Salutation );
                        }
                        // Cambio 27/08. Si se trata de un cambio de record type entonces es necesario borrar el valor del campo
                        // Account Classification para que el usuario pueda seleccionar un valor correcto segun su nuevo record type
                        if( cmp.get("v.isRecTypeChange") && inputFieldName == 'Account_Classification__c' ){
                            inputFieldList[x].set("v.value", null);
                        }
                        
                        // Si el componente esta en la lista de requeridos le agrega la estrella roja.
                        if(requiredList.indexOf(inputFieldName) != -1 ){
                            $A.util.addClass(inputFieldList[x], "customRequired");
                        }

                        if (inputFieldName == "Name" && inputFieldValue != undefined) {
                            if(currentRecordObject.IsPersonAccount) {
                                cmp.set("v.originalName", inputFieldValue.FirstName + inputFieldValue.LastName );
                            } else {
                                cmp.set("v.originalName", inputFieldValue );
                            }
                        }
                        
                    }
                }
            }
            // Habilita todos los botones (Close y Save)
            cmp.set("v.spinnerSaving", false);
            
        }
    },
    
    handleOnError : function(cmp, evt, hlpr){
        // Si hay algun error con la carga del formulario, muestra el detalle en un toast y se cierra el componente        
        let message = evt.getParams().detail + "\n" + evt.getParams().message;
        if(cmp.get("v.userHasAccess")){
            cmp.find("notificationsLibrary").showNotice({
                "variant": "error",
                "header": "Error loading the record",
                "title": 'Error',
                "message": message,
                closeCallback: function() {
                    hlpr.navigateToRecord(cmp, cmp.get("v.recordId"));
                }
            });
        }
        
        
    },
    /*
    handleConvertChange: function(cmp, evt, hlpr){
        var inputFieldList = cmp.find("inputField");
		for(let x in inputFieldList){              
            var inputField = inputFieldList[x];
			var inputFieldName = inputField.get("v.fieldName");
            alert(inputFieldName);
             $A.util.addClass(inputFieldList[x], "customRequired");
        }
    }, // handleConvertChange
    */
    
    handleChangeRequired: function(cmp, evt, hlpr){
        //console.log("handleChangeRequired");
        // Checkea que los campos requeridos no esten vacios, si lo estan los pinta de rojo.
        var source = evt.getSource();
        var params = evt.getParams();
        
        //console.log(JSON.stringify(params));
        //console.log(source.get("v.fieldName"));
        //console.log(source.get("v.value"));
        //console.log(JSON.stringify(source.get("v.value")));
        
        var currentRecordObject = cmp.get("v.currentRecordObject");
        // WorkAround Name de PersonAccount
        
        if(currentRecordObject.IsPersonAccount && source.get("v.fieldName") == "Name"){
            
            if(params.hasOwnProperty('salutation') && params.hasOwnProperty('firstName') && params.hasOwnProperty('lastName')){
                
                var list = [params.salutation, params.firstName, params.lastName];
                var error = false;
                
                for(var i = 0; i<list.length; i++){
                    error = error || hlpr.isInputInvalid(cmp, list[i]);
                }
                //cmp.set("v.requiredName", error);
                hlpr.highlightRequiredFields(cmp, source, source.get("v.fieldName"), error);
                
                cmp.set("v.firstName", params.firstName);
                cmp.set("v.lastName", params.lastName);
                cmp.set("v.salutation", params.salutation);
            }
            
        } else{
            let inputValue = source.get("v.value");
            
            if( hlpr.isCompoundField(cmp, inputValue) ) {
                let changeError = false;
                for(let z in inputValue){
                    //console.log("Non required Compound Inner FieldName: " + z + " / FieldValue: " + inputValue[z]);
                    changeError = changeError|| hlpr.isInputInvalid(cmp, inputValue);
                }
                hlpr.highlightRequiredFields(cmp, source, source.get("v.fieldName"), changeError);
                
            } else {
                hlpr.highlightRequiredFields(cmp, source, source.get("v.fieldName"), hlpr.isInputInvalid(cmp, inputValue));
                
            }
            
        }
        
    },
    
    handleOnSubmit : function(cmp, evt, hlpr){
        evt.preventDefault();
        
        // Crea un objeto con todos los campos a guardar.
        var inputFieldList = cmp.find("inputField");
        console.log(inputFieldList);
        var accountFieldsObject = {};
        var requiredFieldError = false;
        var requiredList = cmp.get("v.requiredList");
        var currentRecordObject = cmp.get("v.currentRecordObject");
        var newName = cmp.get("v.originalName");
        
        // Reset potential
        if (currentRecordObject.Potential__c) {
            var convert = cmp.find("convertPotential");
            if (convert.get("v.checked")) {
                accountFieldsObject["Potential__c"] = false;
            }          
        }
        
        if(!Array.isArray(inputFieldList)){
            inputFieldList = [inputFieldList];
        }
        
        for(let x in inputFieldList){  
            
            var inputField = inputFieldList[x];
            if(inputField != undefined && $A.util.isObject(inputField) && !$A.util.isEmpty(inputField)){
                var inputFieldName = inputField.get("v.fieldName");
                var inputFieldValue = inputField.get("v.value");
                if(inputFieldName != undefined){                     
                    // Forma el objecto a guardar
                    //accountFieldsObject[inputFieldName] = inputFieldValue;                    
                    if( requiredList.indexOf(inputFieldName) != -1 ){                        
                        // WorkAround Name PersonAccount
                        if(currentRecordObject.IsPersonAccount && inputFieldName == 'Name'){
                            if( hlpr.isCompoundField(cmp, inputFieldValue) ){
                                inputFieldValue = { firstName: cmp.get("v.firstName"), lastName : cmp.get("v.lastName"),
                                                   salutation : cmp.get("v.salutation")
                                                 	};
                            }
                        }
                        
                        if( hlpr.isCompoundField(cmp, inputFieldValue) ) {                            
                            var compoundFieldError = false;
                            // Si un campo compuesto es requerido entonces todos sus subvalores son requeridos y se tienen que verificar.
                            for(let y in inputFieldValue){                                
                                let innerCompoundError = hlpr.isInputInvalid(cmp, inputFieldValue[y]);
                                compoundFieldError = compoundFieldError || innerCompoundError;                                
                                if(!innerCompoundError){
                                    accountFieldsObject[y] = inputFieldValue[y];
                                }                                
                            }                            
                            hlpr.highlightRequiredFields(cmp, inputField, inputFieldName, compoundFieldError);                            
                            requiredFieldError = requiredFieldError || compoundFieldError;                            
                        } else {                            
                            let commonFieldError = hlpr.isInputInvalid(cmp, inputFieldValue);                            
                            if(!commonFieldError){
                                accountFieldsObject[inputFieldName] = inputFieldValue;
                            }                            
                            hlpr.highlightRequiredFields(cmp, inputField, inputFieldName, commonFieldError);                            
                            requiredFieldError = requiredFieldError || commonFieldError;                            
                        }       

                        if(inputFieldName == 'Name'){
                            if(currentRecordObject.IsPersonAccount){
                                newName = cmp.get("v.firstName") + cmp.get("v.lastName");
                            } else {
                                newName = inputFieldValue;
                            }
                        }
                    } 
                    else{
                        if( hlpr.isCompoundField(cmp, inputFieldValue) ) {
                            for(let p in inputFieldValue){
                                accountFieldsObject[p] = inputFieldValue[p];
                            }
                        } else {
                            accountFieldsObject[inputFieldName] = inputFieldValue;
                        }
                    }
                    
                }
            }
        }
        
        if( !requiredFieldError){
            // Para Francia, guardamos automáticamente el SIREN como recorte del SIRET introducido
            if (accountFieldsObject['BillingCountryCode'] == 'FR'
                && accountFieldsObject['VAT_Number__c'] != null
                && accountFieldsObject['VAT_Number__c'] != '') {
                accountFieldsObject['VAT_Number_2__c'] = (accountFieldsObject['VAT_Number__c']).substring(0,9);
            }
            
            console.log("accountFieldsObject: " + JSON.stringify(accountFieldsObject));
            hlpr.updateAccount(cmp, hlpr, accountFieldsObject, newName != cmp.get("v.originalName"));
            
        } else {
            
            console.log("Required Fields Validation Failed");
        }
        
        
    },
    
    handleOnCancel : function(cmp, evt, hlpr){
        
        cmp.set("v.stopReload", true);
        hlpr.navigateToRecord(cmp, cmp.get("v.recordId"));
        
    },
    
    handleScrollToTop : function(cmp, evt, hlpr){
        
        cmp.find("innerScroller").scrollTo('top');
        
    },
    
    itemsChange : function(cmp, evt, hlpr){
        
        var fieldList = cmp.get("v.fieldList");
        var layoutSections = cmp.get("v.layoutSections");
        
        fieldList.forEach(function (item, index){
            
            layoutSections.forEach(function (arrayItem){
                
                if(!$A.util.isEmpty(arrayItem.fieldList)){
                    
                    if(arrayItem.label == item){
                        
                        var attributeString = 'v.' + item;
                        //console.log(item);
                        arrayItem.label = cmp.get(attributeString);
                        
                    }
                    
                }
                
            });
            
        });
        cmp.set("v.layoutSections", layoutSections);
        
    }
    
})