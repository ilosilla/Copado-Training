({
    doInit : function(component, event, helper) {
        var pickedUpRadioOptionsClientePresente = [
            {'label': $A.get("$Label.c.Yes_the_customer_picks_up_the_phone"), 'value': 'Yes'},
            {'label': $A.get("$Label.c.Qualification_Is_not_the_customer"), 'value': 'No'} 
        ],
            pickedUpRadioOptionsClientSatisfied = [
                {'label': $A.get("$Label.c.Yes"), 'value': 'Satisfied'},
                {'label': $A.get("$Label.c.No"), 'value': 'NotSatisfied'} 
            ],
            pickedUpRadioOptionsProfessionalAdvice = [
                {'label': $A.get("$Label.c.Qualification_Yes_the_client_has_received_advice_from_a_contractor"), 'value': 'true'},
                {'label': $A.get("$Label.c.Qualification_No_the_client_has_not_received_advice_from_a_contractor"), 'value': 'false'} 
            ],
            pickedUpRadioOptionsUniversalStoreAppointment = [
                {'label': $A.get("$Label.c.Yes"), 'value': 'YesUniversalStoreAppointment'},
                {'label': $A.get("$Label.c.No"), 'value': 'NoUniversalStoreAppointment'} 
            ],
            pickedUpRadioOptionsPersonalizedSample = [
                {'label': $A.get("$Label.c.Yes"), 'value': 'YesPersonalizedSample'},
                {'label': $A.get("$Label.c.No"), 'value': 'NoPersonalizedSample'} 
            ],
            pickedUpRadioOptionsHelpOrganizeProject = [
                {'label': $A.get("$Label.c.Yes"), 'value': 'YesHelpOrganizeProject'},
                {'label': $A.get("$Label.c.No"), 'value': 'NoHelpOrganizeProject'} 
            ],
            pickedUpRadioOptionsStartSoon = [
                {'label': $A.get("$Label.c.Yes"), 'value': 'YesStartSoon'},
                {'label': $A.get("$Label.c.No"), 'value': 'NoStartSoon'} 
            ],
            pickedUpRadioOptionsTelephoneAdvice = [
                {'label': $A.get("$Label.c.Yes"), 'value': 'YesTelephoneAdvice'},
                {'label': $A.get("$Label.c.No"), 'value': 'NoTelephoneAdvice'} 
            ],
            pickedUpRadioOptionsReasonNoAdvice = [
                {'label': $A.get("$Label.c.Qualification_I_don_t_have_time_right_now"), 'value': "I don't have any time at this moment"},
                {'label': $A.get("$Label.c.Qualification_I_want_to_consult_it"), 'value': 'I want to consult it'},
                {'label': $A.get("$Label.c.Qualification_I_am_checking_some_other_options"), 'value': 'I am checking some other options'},
                {'label': $A.get("$Label.c.Qualification_I_have_just_bought_other_materials"), 'value': 'I have just buy other materials'},
                {'label': $A.get("$Label.c.Qualification_Excessive_Price"), 'value': 'Excessive Price'},
                {'label': $A.get("$Label.c.Qualification_Deferred_Payment"), 'value': 'Deferred Payment'},
                {'label': $A.get("$Label.c.Qualification_What_if_I_don_t_like_the_final_result"), 'value': "What if I don't like the final result"},
                {'label': $A.get("$Label.c.Qualification_I_have_little_time_to_manage_the_project"), 'value': 'I have little time to manage the project'},
                {'label': $A.get("$Label.c.Qualification_I_m_stressed_about_the_project"), 'value': "I'm stressed about the project"},
                {'label': $A.get("$Label.c.Qualification_I_doubt_if_I_m_making_the_best_choice"), 'value': "I doubt if I'm making the best choices"},
                {'label': $A.get("$Label.c.Qualification_The_product_range_does_not_fit_my_needs"), 'value': 'The product range does not fit my needs'},
                {'label': $A.get("$Label.c.Qualification_Material_collection"), 'value': 'Material collection'}
            ],
            pickedUpRadioOptionsTypeOfSale = [
                {'label': $A.get("$Label.c.Qualification_By_phone_sales"), 'value': 'ByPhoneSales'},
                {'label': $A.get("$Label.c.Qualification_In_store_appointment"), 'value': 'InStoreAppointment'} 
            ];
        
        var comboOptionsProfessional = [
            {'label': $A.get("$Label.c.Qualification_The_client_is_a_professional"), 'value': 'Profesional'},
            {'label': $A.get("$Label.c.Qualification_The_client_is_not_a_professional"), 'value': 'No Profesional'} 
        ],
            comboOptionsReasonNotSatisfied = [
                {'label': $A.get("$Label.c.Qualification_I_don_t_like_it"), 'value': "I don’t like it"},
                {'label': $A.get("$Label.c.Qualification_Cheaper_in_other_company"), 'value': "Cheaper in other company"} ,
                {'label': $A.get("$Label.c.Qualification_The_product_I_like_is_not_available"), 'value': "The product I like is not available"} ,
                {'label': $A.get("$Label.c.Qualification_I_ve_changed_my_mind"), 'value': "I change my mind"} 
            ],
            comboOptionsReasonProjectPostponed = [
                {'label': $A.get("$Label.c.Qualification_I_m_stressed_about_the_project"), 'value': 'I am stressed'},
                {'label': $A.get("$Label.c.Qualification_I_am_undecided_about_the_materials"), 'value': 'I am undecided about the materials'},
                {'label': $A.get("$Label.c.Qualification_I_need_more_time_to_organize"), 'value': 'I need more time to organize'},
                {'label': $A.get("$Label.c.Qualification_Lack_of_knowledge_of_the_brand"), 'value': 'Lack of knowledge of the range and advantages of the brand'}
            ];
        
        var dualListBoxOptionsTypeofProject = [
            
            {'label': $A.get('$Label.c.Qualification_Bathroom'), 'value' :	'Bathroom'},
            {'label': $A.get('$Label.c.Project_Zone_Gym'), 'value' : 'Gym'},
            {'label': $A.get('$Label.c.Project_Zone_Flooring'), 'value' : 'Flooring'},
            {'label': $A.get('$Label.c.Kitchen'), 'value' : 'Kitchen'},
            {'label': $A.get('$Label.c.Project_zone_Living_room'), 'value' : 'Living room'},
            {'label': $A.get('$Label.c.Project_Zone_Dining_room'), 'value' : 'Dining room'},
            {'label': $A.get('$Label.c.Room'), 'value' : 'Room'},
            {'label': $A.get('$Label.c.Project_Zone_Swimming_pool'), 'value' : 'Swimming pool'},
            {'label': $A.get('$Label.c.Project_Zone_Pavement'), 'value' : 'Pavement'},
            {'label': $A.get('$Label.c.Qualification_Whole_remodelation'), 'value' : 'Whole remodelation'},
            {'label': $A.get('$Label.c.Project_Zone_Others'), 'value' : 'Others'}
        ],
            
            dualListBoxOptionsInterestMaterials = [
                {'label': $A.get('$Label.c.Materials_Furniture'), 'value' : 'Furniture'},
                {'label': $A.get('$Label.c.Materials_Taps'), 'value' : 'Taps'},
                {'label': $A.get('$Label.c.Materials_Countertops'), 'value' : 'Countertops'},
                {'label': $A.get('$Label.c.Materials_Bathtubs'), 'value' : 'Bathtubs'},
                {'label': $A.get('$Label.c.Products_Shower'), 'value' : 'Shower'},
                {'label': $A.get('$Label.c.Products_Shower_tray'), 'value' : 'Shower tray'},
                {'label': $A.get('$Label.c.Products_Shower_column'), 'value' : 'Shower column'},
                {'label': $A.get('$Label.c.Products_Sprinklers'), 'value' : 'Sprinklers'},
                {'label': $A.get('$Label.c.Products_Bulkheads'), 'value' : 'Bulkheads'},
                {'label': $A.get('$Label.c.Products_Washbasins'), 'value' : 'Washbasins'},
                {'label': $A.get('$Label.c.Products_Sanitary'), 'value' : 'Sanitary'},
                {'label': $A.get('$Label.c.Products_Radiators'), 'value' : 'Radiators'},
                {'label': $A.get('$Label.c.Products_Bathroom_accessories'), 'value' : 'Bathroom accessories'},
                {'label': $A.get('$Label.c.Products_Wardrobe'), 'value' : 'Wardrobe'},
                {'label': $A.get('$Label.c.Products_Dressing_room'), 'value' : 'Dressing room'},
                {'label': $A.get('$Label.c.Project_Zone_Others'), 'value' : 'Other'}
            ];
        
        component.set("v.pickedUpRadioOptionsClientePresente", pickedUpRadioOptionsClientePresente);
        component.set("v.pickedUpRadioOptionsClientSatisfied", pickedUpRadioOptionsClientSatisfied);
        component.set("v.pickedUpRadioOptionsProfessionalAdvice", pickedUpRadioOptionsProfessionalAdvice);
        component.set("v.pickedUpRadioOptionsUniversalStoreAppointment", pickedUpRadioOptionsUniversalStoreAppointment);
        component.set("v.pickedUpRadioOptionsPersonalizedSample", pickedUpRadioOptionsPersonalizedSample);
        component.set("v.pickedUpRadioOptionsHelpOrganizeProject", pickedUpRadioOptionsHelpOrganizeProject);
        component.set("v.pickedUpRadioOptionsStartSoon", pickedUpRadioOptionsStartSoon);
        component.set("v.pickedUpRadioOptionsTelephoneAdvice", pickedUpRadioOptionsTelephoneAdvice);
        component.set("v.pickedUpRadioOptionsReasonNoAdvice", pickedUpRadioOptionsReasonNoAdvice);
        component.set("v.pickedUpRadioOptionsTypeOfSale", pickedUpRadioOptionsTypeOfSale);
        component.set("v.dualListBoxOptionsTypeofProject", dualListBoxOptionsTypeofProject);
        component.set("v.dualListBoxOptionsInterestMaterials", dualListBoxOptionsInterestMaterials);
        
        component.set("v.comboOptionsProfessional", comboOptionsProfessional);
        component.set("v.comboOptionsReasonNotSatisfied", comboOptionsReasonNotSatisfied);
        component.set("v.comboOptionsReasonProjectPostponed", comboOptionsReasonProjectPostponed);
		
        helper.setUserName(component);
        helper.setToday(component);
        
        // Camino tomado inicial
        // Cada pantalla tiene un estado, cada estado puede tener varios valores, true, false, irrelevant (siempre lleva a la misma pantalla sin importar la decision)
        // Cada pantalla tiene fieldsToUpdate de Opportunity y accountFieldsTo update.
        component.set("v.pathList", [{'estado' : 'Inicio', 'valor': true, 'fieldsToUpdate' : {}, 'accountFieldsToUpdate' : {}}]);
        component.set("v.currentPathKey", 'Inicio');
        component.set("v.currentPathValue", true);
        
        component.set("v.successFailureFinalScreen", false);
        component.set("v.firstScreen", true);
        component.set("v.lastScreen", false);
        
        console.log("recordID: update 48: " + component.get("v.opportunity").Id);
        
    },
    
    changeScreen : function(cmp, evt, hlpr){
        // Sirve de handler para el metodo llamado por el argumentario y para el evento 
        // llamado por CierreCitaTienda. Lo unico que cambia son los parametros que se reciben
        // del evento.
        
        var params;
        var source = evt.getSource().getName(); // cJMArgumentarioCmp  cJMCierre_Cita_Tienda
        
        if(source === "cArgumentarioCmp"){
            // Condicion de avance de pantalla normal
            params = evt.getParam("arguments");
            
        } else if(source === "cCierre_Cita_Tienda"){
            // Si CierreCitaTienda termino de guardar entonces setea los valores que retorno.
            params = evt.getParams();
            
            cmp.set("v.appointmentLocation", params.companyComboboxValue + ", " 
                    + params.salesOrgComboboxValue + ", " + params.salesOfficeComboboxValue);
            var auxDate = hlpr.formatDate(cmp, params.dateCita);
            cmp.set("v.displayDate", auxDate);
            
        } 

        
        if(params){
            var pathList = cmp.get("v.pathList");
            var pathListLength = pathList.length;
            var currentPath = pathList[pathListLength - 1]; // path actual
            
            if(params.action == "Previous"){
                // si no estamos en la primera pantalla
                if(currentPath.estado != 'Inicio'){
                    // Si el estado anterior en la lista es 'inicio' la setea como la primera pantalla
                    if(pathList[pathListLength - 2].estado == 'Inicio'){
                        cmp.set("v.firstScreen", true);
                    }
                    
                    // Al volver atras borra el ultimo elemento de la lista y setea el estado y valor actual para renderizar pantallas.
                    pathList.pop();
                    // Setea la decision actual como la ultima de la lista
                    cmp.set("v.currentPathKey", pathList[pathList.length - 1].estado);
                    cmp.set("v.currentPathValue", pathList[pathList.length - 1].valor);
                    cmp.set("v.pathList", pathList);
                    
                    console.log("pathList after back: " + JSON.stringify(pathList));
                    
                }
            }
            else if(params.action == "Next"){
                
                if(!cmp.get("v.lastScreen")){
                    
                    hlpr.validateFields(cmp, hlpr);
                    var error = cmp.get("v.error") || cmp.get("v.dateError");
                    
                    // Si CierreCitaTienda esta listo llama a guardar los valores
                    // Esto setea requiredError que se usa mas adelante.
                    var childCmp = cmp.find("cierreTiendaCmp");
                    
                    if(childCmp !== undefined && source === 'cArgumentarioCmp'){
                        childCmp.saveOppDetails();
                        error = error || cmp.get("v.requiredError");
                    }
                    
                    if(!error){
                        
                        if(currentPath.estado === 'Inicio'){
                            cmp.set("v.firstScreen", false);
                        }
                        
                        // Crea una nueva decision dependiendo de los datos en pantalla y la inserta en la lista de decisiones.
                        var pathListNext = hlpr.createNode(cmp, hlpr, currentPath);
                        pathList.push(pathListNext);
                        
                        cmp.set("v.pathList", pathList);
                        cmp.set("v.currentPathKey", pathListNext.estado);
                        cmp.set("v.currentPathValue", pathListNext.valor);
                        
                        // Si la pantalla siguiente es la final junta todos los campos a actualizar.
                        if(cmp.get("v.lastScreen")){
                            hlpr.mergeFieldsToUpdate(cmp);
                        }
                        
                        console.log("Next path: " + JSON.stringify(pathListNext));
                        
                    }
                }   
            }
        }
    },
    
    dateValidation : function(cmp, evt, hlpr){
        //console.log("Params: " + JSON.stringify(evt.getParams()));
        //console.log("Source: " + evt.getSource());
        //console.log("Value: " + evt.getSource().get("v.value"));
        cmp.set("v.dateError", false);
        hlpr.validateDate(cmp, evt.getSource());
   	},
    
    reloadStage : function(cmp){
        // Resetea atributos de datos y control.
        cmp.set("v.currentPathKey", 'Inicio');
        cmp.set("v.currentPathValue", true);
        cmp.set("v.firstScreen", true);
        cmp.set("v.lastScreen", false);
        cmp.set("v.error", false);
        cmp.set("v.successFailureFinalScreen", false);
        cmp.set("v.fieldsToUpdate", {});
        cmp.set("v.accountFieldsToUpdate", {});
        
        cmp.set("v.pathList", [{'estado' : 'Inicio', 'valor': true, 'fieldsToUpdate' : {}, 'accountFieldsToUpdate' : {}}]);
        
        cmp.set("v.taskCreatedId" , undefined);
        cmp.set("v.dateValueReminder" , undefined);
        cmp.set("v.dateValueProjectStart" , undefined);
        cmp.set("v.dateValueProjectEnd" , undefined);
        cmp.set("v.dateValueReasonDontHaveTime" , undefined);
        cmp.set("v.displayDate" , undefined);
        cmp.set("v.textScreenReasonDontHaveTimeWantToConsultValue" , undefined);
        cmp.set("v.textScreenReasons" , undefined);
        
    }
})