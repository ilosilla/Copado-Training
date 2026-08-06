({
    
    validateFields : function(cmp, hlpr){
        // Todos los input fields tiene aura:id fieldToValidate
        cmp.set("v.error", false); 
        var element = cmp.find('fieldToValidate');
        var inputMap = {};
        
        if(element !== undefined){
            // Si solamente tiene un campo para verificar primero lo inserta en un array y despues hace lo mismo
            // que si tuviera varios elementos.
            if(!Array.isArray(element)){
                element = [element];
            }
            element.forEach(function(inputCmp){
                // Si los valores de entrada son invalidos 
                console.log("Input Map: \n Name: "+ inputCmp.get("v.name")+ "\nValue: "+inputCmp.get("v.value"));
                if( !inputCmp.get("v.validity").valid){
                    inputCmp.showHelpMessageIfInvalid();
                    cmp.set("v.error", true);
                }
                else {
                    // Como para facilitar la validacion todos los input tienen el mismo aura:id 
                    // y para evitar almacenar los valores de input de input en atributos 
                    // se mapea los nombres de los input con sus respectivos valores.
                    inputMap[ inputCmp.get("v.name") ] = inputCmp.get("v.value");
                }
            });
            
            cmp.set("v.inputMap", inputMap);
        }
        
        var dateField = cmp.find('dateFieldToValidate');
        
        cmp.set("v.dateError", false);
        
        if(dateField != undefined){
            if(!Array.isArray(dateField)){
                dateField = [dateField];
            }
            
            dateField.forEach(function(inputCmp){
           		hlpr.validateDate(cmp, inputCmp);
            });
        }
        

    },
    
    completeStage : function(cmp, ReasonPending){
        
        // Avanza la oportunidad a la siguiente etapa.
        cmp.set("v.lastScreen", true);
        cmp.set("v.successFailureFinalScreen", true);
        
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        fieldsToUpdate.StageName = "Pending";
        
        switch(ReasonPending){
            case 'universalStoreAppointment':
                fieldsToUpdate.Reason_Pending__c = 'In shop date';
                break;
            case 'typeOfSale_online':
                fieldsToUpdate.Reason_Pending__c = 'Pending checkout';
                break;
            case 'linkTarea':
                fieldsToUpdate.StageName = "New";
                break;
        }
        
    },
    
    discardOpportunity : function(cmp,reason){
        
        // Cierra la oportunidad como perdida y actuliza campos
        cmp.set("v.lastScreen", true);
        cmp.set("v.successFailureFinalScreen", true);
        
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        fieldsToUpdate.StageName = "Closed Lost";
        
        switch(reason){
            case 'universalStoreAppointment':
                fieldsToUpdate.Close_Mode__c = "Not interested";
                break;
            case 'personalizedSampleOrder':
                fieldsToUpdate.Close_Mode__c = "More samples";
                break;
        }
        
    },
    
    crearRecordatorio : function(cmp, date, taskSubject){
        cmp.set("v.spinner", true);
        // crea la tarea de recordatorio para llamar al cliente.
        var action = cmp.get("c.createTask");
        var opportunity = cmp.get("v.opportunity");
        
        action.setParams({'recordId' : opportunity.Id,
                          'taskDate' : date,
                          'taskSubject' : taskSubject});
        
        action.setCallback(this, function(response){
            
            if(response.getState() === "SUCCESS"){
                console.log(response.getReturnValue());
                cmp.set("v.taskCreatedId", response.getReturnValue());
                cmp.set("v.spinner", false);
            }
            else{
                alert("Error al crear el recordatorio para la fecha: " + date);
            }
            
        });
        
        $A.enqueueAction(action);
    },
    
    setUserName : function(cmp){
        
        var action = cmp.get("c.getUserName");
        
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                cmp.set("v.userName", response.getReturnValue());
            }
            else{
                alert("Error getting the user");
            }            
        });
        
        $A.enqueueAction(action);
        
    },
    
    validateDate : function (cmp, inputCmp){
        
        var dateMin = cmp.get("v.dateMin");
        var label = $A.get("$Label.c.Qualification_Project_end_date");
        if(inputCmp.get("v.label") == label){
            dateMin = cmp.get("v.dateValueProjectStart");
        }
        
        var dateValue = inputCmp.get("v.value");    
        var isValidDate = new Date(dateValue);
        
        if(dateValue == null || dateValue == undefined || dateValue == "" || dateValue < dateMin 
           || isValidDate == "Invalid Date"){
            
            inputCmp.set("v.errors", [{message: $A.get("$Label.c.Qualification_Message_when_missing_date")}]);
            
            if(isValidDate == "Invalid Date"){
                inputCmp.set("v.errors", [{message: $A.get("$Label.c.Qualification_Message_when_invalid_date") }]);
            } else if(dateValue < dateMin){
                inputCmp.set("v.errors", [{message: $A.get("$Label.c.Qualification_Message_when_past_date") + " " + dateMin}]);
            }
            
            
            cmp.set("v.dateError", true);
        } else {
            inputCmp.set("v.errors", null);
            
        } 
        
    },
    
    setToday : function(cmp){
        
        // Crea una fecha con el dia de hoy y la setea como la fecha minima para el resto de las fechas a ingresar.
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        cmp.set("v.dateMin", today);
        
    },
    
    formatDate : function(cmp, dateF){
        
        // Formatea date/time y lo ajusta con la diferencia horaria.
        var difDate = new Date(dateF);
        difDate.setHours(difDate.getHours() + 1 + difDate.getTimezoneOffset()/60);
        var formatedDate = $A.localizationService.formatDateTime(difDate, "YYYY-MM-DD HH:mm:ss");
        //console.log("Original date: " + dateF);
        //console.log("Formated Date: " + formatedDate);
        
        return formatedDate;
        
    },
    
    formatDualList : function(cmp, list){
        var formatedDualList;
        if(list != undefined){
            formatedDualList = list.join(";");
        }
        return formatedDualList;
    },
    
    mergeFieldsToUpdate : function(cmp){
        
        // Como cada estado de pathList guarda los campos a actualizar por separado,
        // una vez que se terminan las pantallas hay que insertar todos los campos de pathList
        // en un solo objeto fieldsToUpdate. Lo mismo se hace para accountFieldsToUpdate.
        var pathList = cmp.get("v.pathList");
        var fieldsToUpdate =  cmp.get("v.fieldsToUpdate");
        var accountFieldsToUpdate =  cmp.get("v.accountFieldsToUpdate");
        
        for(var i = 0; i < pathList.length; i++){
            fieldsToUpdate = Object.assign({}, fieldsToUpdate, pathList[i].fieldsToUpdate);
            accountFieldsToUpdate = Object.assign({}, accountFieldsToUpdate, pathList[i].accountFieldsToUpdate);
        }
        
        cmp.set("v.fieldsToUpdate", fieldsToUpdate);
        cmp.set("v.accountFieldsToUpdate", accountFieldsToUpdate);
        
        console.log("merge fieldsToUpdate: ", JSON.stringify(fieldsToUpdate));
        console.log("merge accountFieldsToUpdate: ", JSON.stringify(accountFieldsToUpdate));
        
    },
    
    createNode : function(cmp, hlpr, currentPath){
        // Crea un nodo de decision 'pathListNext' como un objeto cuyas propiedades dependen del estado actual
        //  'currentPath' de las pantallas. 
        //  Todos los nodos tienen que tener un estado y un valor, los campos que se tienen que actualizar son opcionales
        //  ya que la pantalla puede ser solo texto.
        //  Asi que si se quiere insertar un nuevo nodo (pantalla) solamente hace falta espeficiar el siguiente nodo y las condiciones que llevan a eso.
        //  Ademas de configurar otro nodo para que vaya al nuevo nodo que se quiere tener.
        var pathListNext = {'fieldsToUpdate': {}, 'accountFieldsToUpdate': {}};
        var inputMap = cmp.get("v.inputMap");
        
        // Asigna la siguiente decion a tomar y si lo necesita llama a crear o modificar objetos 
        switch(currentPath.estado){
            case 'Inicio':
                // Pantalla inicial
                var elementValue = inputMap['pickedUpRadioClientePresente'];
                pathListNext.estado = "clientePresente";
                
                switch(elementValue){
                    case "Yes":
                        pathListNext.valor = true;
                        break;
                    case "No":
                        pathListNext.valor = false;
                        break;
                }
                break;
            case 'clientePresente':
                if(currentPath.valor){
                    // Cliente satisfecho?
                    var elementValue = inputMap ['pickedUpRadioClientSatisfied'];
                    pathListNext.estado = 'clienteSatisfecho';
                    
                    switch(elementValue){
                        case "Satisfied":
                            pathListNext.valor = true;
                            pathListNext.fieldsToUpdate.Interest__c = true;
                            break;
                        case "NotSatisfied":
                            pathListNext.valor = false;
                            pathListNext.fieldsToUpdate.Interest__c = false;
                            break;
                    }
                }
                else if(!currentPath.valor){
                    pathListNext.estado = 'recordatorioCreado';
                    pathListNext.valor = true;
                    
                    var auxDate = hlpr.formatDate(cmp, cmp.get("v.dateValueReminder"));
                    cmp.set("v.displayDate", auxDate);
                }
                break;
            case 'clienteSatisfecho':
                if(currentPath.valor){
                    
                    var elementValue = inputMap ['comboProfessional'];
                    pathListNext.accountFieldsToUpdate.Professional__c = elementValue;
					
                    switch(elementValue){
                        case "Profesional":
                            pathListNext.estado = 'professionalCommonPath';
                            pathListNext.valor = true;
                            break;
                        case "No Profesional":
                            pathListNext.estado = 'professional';
                            pathListNext.valor = false;
                            break;
                    }
                } else if(!currentPath.valor){
                    pathListNext.estado = 'reasonNotSatisfied';
                    pathListNext.valor = 'irrelevant';
                    
                    pathListNext.fieldsToUpdate.Reason_Not_Interest__c = inputMap ['comboReasonNotSatisfied'];
                } 
                break;
            case 'recordatorioCreado':
                if(currentPath.valor){
                    pathListNext.estado = 'linkTarea';
                    pathListNext.valor = true;
                    
                    hlpr.crearRecordatorio(cmp, hlpr.formatDate(cmp, cmp.get("v.dateValueReminder")), $A.get("$Label.c.Llamada_reprogramada"));
                    hlpr.completeStage(cmp, 'linkTarea');
                }
                break;
            case 'reasonNotSatisfied':
                if(currentPath.valor == 'irrelevant'){
                    
                    var elementValue = inputMap ['pickedUpRadioPersonalizedSample'] ;
                    pathListNext.estado = 'personalizedSamples';
                    
                    switch(elementValue){
                        case "YesPersonalizedSample":
                            pathListNext.valor = true;
                            break;
                        case "NoPersonalizedSample":
                            pathListNext.valor = false;
                            break;
                    }
                }
                break;
            case 'professional':
                if(!currentPath.valor){
                    //professionalAdvice
                    pathListNext.estado = 'professionalCommonPath';
                    pathListNext.valor = true;
                    
                    pathListNext.fieldsToUpdate.Contractor_Consulting__c = (inputMap ['pickedUpRadioProfessionalAdvice'] === 'true');
                }
                break;
            case 'professionalCommonPath':
                // typeOfProject
                if(currentPath.valor){
                    pathListNext.estado = 'typeOfProject';
                    pathListNext.valor = 'irrelevant';
                    
                    pathListNext.fieldsToUpdate.ReasonProject__c = inputMap ['textCauseOfProject'];
                    pathListNext.fieldsToUpdate.Project_Zone__c = hlpr.formatDualList(cmp, inputMap ['dualListTypeOfProject'] );
                    pathListNext.fieldsToUpdate.Project_Type__c = inputMap ['textTypeOfProject'];
                }
                break;
            case 'personalizedSamples':
                if(!currentPath.valor){
                    //UniversalStoreAppointment
                    var elementValue = inputMap ['pickedUpRadioUniversalStoreAppointment'];
                    pathListNext.estado = 'universalStoreAppointment';
                    
                    switch(elementValue){
                        case "YesUniversalStoreAppointment":
                            pathListNext.valor = true;
                            break;
                        case "NoUniversalStoreAppointment":
                            pathListNext.valor = false;
                            
                            hlpr.discardOpportunity(cmp, 'universalStoreAppointment');
                            break;
                    }
                }else if(currentPath.valor){
                    //personalized sample order
                    pathListNext.estado = 'personalizedSampleOrder';
                    pathListNext.valor = 'irrelevant';
                    
                    hlpr.discardOpportunity(cmp, 'personalizedSampleOrder');
                }
                break;
            case 'typeOfProject':
                if(currentPath.valor == 'irrelevant'){
                    //interestMaterials
                    pathListNext.estado = 'interestMaterials';
                    pathListNext.valor = 'irrelevant';
                    
                    pathListNext.fieldsToUpdate.Materials__c = hlpr.formatDualList(cmp, inputMap ['dualListInterestMaterials'] );
                }
                break;
            case 'universalStoreAppointment':
                if(currentPath.valor){
                    //endAppointmentUniversalStore
                    pathListNext.estado = 'endAppointmentUniversalStore';
                    pathListNext.valor = 'irrelevant';
                    
                    hlpr.completeStage(cmp, 'universalStoreAppointment');
                }
                break;
            case 'interestMaterials':
                if(currentPath.valor == 'irrelevant'){
                    //helpOrganizeProject
                    var elementValue = inputMap ['pickedUpRadioHelpOrganizeProject'] ;
                    pathListNext.estado = 'helpOrganizeProject';
                    
                    switch(elementValue){
                        case "YesHelpOrganizeProject":
                            pathListNext.valor = true;
                            break;
                        case "NoHelpOrganizeProject":
                            pathListNext.valor = false;
                            break;
                    }
                }
                break;
            case 'helpOrganizeProject':
                if(currentPath.valor){
                    // startSoon
                    var elementValue = inputMap ['pickedUpRadioStartSoon'] ;
                    pathListNext.estado = 'startSoon';
                    
                    pathListNext.fieldsToUpdate.Description = inputMap ['textStartSoon'];
                    pathListNext.fieldsToUpdate.Start_Project_Date__c = cmp.get("v.dateValueProjectStart");
                    
                    switch(elementValue){
                        case "YesStartSoon":
                            pathListNext.valor = true;
                            break;
                        case "NoStartSoon":
                            pathListNext.valor = false;
                            break;
                    }
                    
                } else if(!currentPath.valor){
                    //reasonNoAdvice
                    var elementValue = inputMap ['pickedUpRadioReasonNoAdvice'];
                    pathListNext.estado = 'reasonNoAdviceProjectPostponed';
                    
                    pathListNext.fieldsToUpdate.Reason_Not_Advice__c = elementValue;
                    
                    // En este caso la pantalla es la misma solo cambia el texto.
                    switch(elementValue){
                        case "I don't have any time at this moment":
                            pathListNext.valor = 'dontHaveTime';
                            cmp.set("v.textScreenReasonDontHaveTimeWantToConsultValue", $A.get("$Label.c.Qualification_at_what_time_I_can_call_you_to_continue_helping_you"));
                            break;
                        case "I want to consult it":
                            pathListNext.valor = 'wantToConsult';
                            cmp.set("v.textScreenReasonDontHaveTimeWantToConsultValue", $A.get("$Label.c.Qualification_I_understand_it_is_a_very_important_decision"));
                            break;
                        case "I am checking some other options":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons",$A.get('$Label.c.Qualification_With_Porcelanosa_you_can_be_sure'));
                            break;
                        case "I have just buy other materials":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons", $A.get('$Label.c.Qualification_Perfect_then_we_will_find_the'));
                            break;
                        case "Excessive Price":
                        case "Deferred Payment":
                            pathListNext.valor = 'deferredPayment';
                            break;
                        case "What if I don't like the final result":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons", $A.get("$Label.c.Qualification_text_doutb_final_result") );
                            break;
                        case "I'm stressed about the project":
                            pathListNext.valor = 'irrelevant';
                            
                            var qualificationTextStressed = $A.get("$Label.c.Qualification_text_stressed");
                            cmp.set("v.textScreenReasons", qualificationTextStressed.replace( "{0}", cmp.get("v.opportunity").Account.Name ) ); 
                            
                            break;
                        case "Material collection":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons", $A.get('$Label.c.Qualification_text_Material_collection'));
                            break;
                        case "I have little time to manage the project":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons", cmp.get("v.opportunity").Account.Name + $A.get("$Label.c.Qualification_text_little_time") );
                            break;
                        case "The product range does not fit my needs":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons", $A.get("$Label.c.Qualification_Are_you_referring_to_pavement_flooring_toilets") );
                            break;
                        case "I doubt if I'm making the best choices":
                            pathListNext.valor = 'irrelevant';
                            cmp.set("v.textScreenReasons", $A.get("$Label.c.Qualification_I_doubt_if_I_m_making_the_best_choices") );
                            break;
                    }
                }
                break;
            case 'startSoon':
                if(currentPath.valor){
                    //dateProjectEnd
                    pathListNext.estado = 'dateProjectEnd';
                    pathListNext.valor = 'irrelevant';
                    
                    pathListNext.fieldsToUpdate.End_Project_Date__c = cmp.get("v.dateValueProjectEnd");
                    
                }else if(!currentPath.valor){
                    //reasonProjectPostponed
                    var elementValue = inputMap ['comboReasonProjectPostponed'];
                    pathListNext.estado = 'reasonNoAdviceProjectPostponed';
                    pathListNext.valor = 'irrelevant';
                    
                    pathListNext.fieldsToUpdate.Reason_Project_Postponed__c = elementValue;
                    
                    switch(elementValue){
                        case 'I am stressed':
                            var qualificationTextStressed = $A.get("$Label.c.Qualification_text_stressed");
                            cmp.set("v.textScreenReasons", qualificationTextStressed.replace( "{0}", cmp.get("v.opportunity").Account.Name ) );
                            
                            break;
                        case 'I am undecided about the materials':
                            cmp.set("v.textScreenReasons", $A.get("$Label.c.Qualification_I_doubt_if_I_m_making_the_best_choices") );
                            break;
                        case 'I need more time to organize':
                            cmp.set("v.textScreenReasons", cmp.get("v.opportunity").Account.Name + $A.get("$Label.c.Qualification_text_little_time") );
                            break;
                        case 'Lack of knowledge of the range and advantages of the brand':
                            cmp.set("v.textScreenReasons", $A.get("$Label.c.Qualification_Are_you_referring_to_pavement_flooring_toilets") );
                            break;
                    }
                }
                break;
            case 'dateProjectEnd':
                if(currentPath.valor == 'irrelevant'){
                    //TelephoneAdvice
                    var elementValue = inputMap ['pickedUpRadioTelephoneAdvice'];
                    
                    switch(elementValue){
                        case "YesTelephoneAdvice":
                            pathListNext.estado = 'telephoneAdvice';
                            pathListNext.valor = true;
                            break;
                        case "NoTelephoneAdvice":
                            pathListNext.estado = 'universalStoreAppointment';
                            pathListNext.valor = true;
                            break;
                    }
                }
                break;
            case 'telephoneAdvice':
                if(currentPath.valor){
                    //typeOfSale
                    var elementValue = inputMap ['pickedUpRadioTypeOfSale'];
                    
                    switch(elementValue){
                        case "ByPhoneSales":
                            pathListNext.estado = 'typeOfSale';
                            pathListNext.valor = 'online';
                            break;
                        case "InStoreAppointment":
                            pathListNext.estado = 'universalStoreAppointment';
                            pathListNext.valor = true;
                            break;
                    }
                }
                break;
            case 'typeOfSale':
                if(currentPath.valor == 'online'){
                    //rangeOfColors
                    pathListNext.estado = 'rangeOfColors';
                    pathListNext.valor = 'irrelevant';
                    
                    hlpr.completeStage(cmp, 'typeOfSale_online');
                }
                break;
            case 'appointmentSaleStore':
                if(currentPath.valor == 'irrelevant'){
                    //endStoreSale
                    pathListNext.estado = 'endStoreSale';
                    pathListNext.valor = true;
                }
                break;
            case 'rangeOfColors':
                if(currentPath.valor == 'irrelevant'){
                    //endOnlineSale
                    pathListNext.estado = 'endOnlineSale';
                    pathListNext.valor = true;
                }
                break;
            case 'reasonNoAdviceProjectPostponed':
                if(currentPath.valor == 'dontHaveTime' || currentPath.valor == 'wantToConsult'){
                    pathListNext.estado = 'endReasonTimeConsult';
                    pathListNext.valor = true;
                    
                    var taskName = inputMap ['textReasonDontHaveTimeWantToConsult'];
                    var auxDate = hlpr.formatDate(cmp, cmp.get("v.dateValueReasonDontHaveTimeWantToConsult"));
                    cmp.set("v.dateValueReasonDontHaveTimeWantToConsult", auxDate);
                    
                    hlpr.crearRecordatorio(cmp, auxDate, taskName);
                    
                    cmp.set("v.lastScreen", true);
                    
                } else if(currentPath.valor == 'deferredPayment'){
                    pathListNext.fieldsToUpdate.Number_Of_Instalments__c = parseInt(inputMap ['numberOfInstalments']);
                    pathListNext.estado = 'personalizedSamples';
                    pathListNext.valor = false;
                    
                } else if(currentPath.valor == 'irrelevant'){
                    pathListNext.estado = 'personalizedSamples';
                    pathListNext.valor = false;
                    
                }
                break;
        }
        
        return pathListNext;
    },
    
})