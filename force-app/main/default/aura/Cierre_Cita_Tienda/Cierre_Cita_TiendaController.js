({
    
    doInit : function(component, event, helper){
        
        console.log("ccc update 2");
        
        var companyFieldAPI = component.get("v.companyFieldAPI");
        var salesOrgFieldAPI = component.get("v.salesOrgFieldAPI");
        var salesOfficeAPI = component.get("v.salesOfficeFieldAPI");
        var recordId = component.get("v.recordId");
        
        helper.getFieldDependencies(component, recordId, companyFieldAPI, salesOrgFieldAPI);
        helper.getFieldDependencies(component, recordId, salesOrgFieldAPI, salesOfficeAPI);
        
    },
    
    onControllerFieldChange: function(component, event, helper){
        
        var comboBox = event.getSource();
        var comboValue = comboBox.get("v.value");
        var comboActive = comboBox.get("v.name");
        
        var comboArray = ['company', 'salesOrg', 'salesOffice'];        
        var comboMap = {'company' : 'none',
                        'salesOrg' : 'salesOrgDisabled',
                        'salesOffice' : 'salesOfficeDisabled'
                       };
        
        // Remover requiredError
        component.set("v.requiredError", false);
        
        var indexOfComboActive = comboArray.indexOf(comboActive);
        
        // Control de visibilidad de Comboboxes y Asignación de picklist dependientes
        if(indexOfComboActive != 2){
            
            var salesOrgCombo = component.find("salesOrgId");
            var salesOfficeCombo = component.find("salesOfficeId");
            
            // Habilitar siguiente combo
            var comboToUpdate = comboArray[indexOfComboActive + 1];
            var attributeString = 'v.' + comboMap[comboToUpdate];
            component.set(attributeString, false);
            
            if(indexOfComboActive == 0){
                
                //Flow
                component.set("v.companySelected", comboValue);
                
                // Remover errores
                component.set("v.companyError", false);
                component.set("v.salesOrgError", false);
                component.set("v.salesOfficeError", false);
                
                // Deshabilitar último comboBox
                comboToUpdate = comboArray[indexOfComboActive + 2];
                salesOfficeCombo.set("v.value", null);
                attributeString = 'v.' + comboMap[comboToUpdate];
                
                component.set(attributeString, true);
                
                var fieldDependenciesCompanySalesOrg = component.get("v.fieldDependenciesCompanySalesOrg");
                var dependentFieldsKeysList1 = Object.keys(fieldDependenciesCompanySalesOrg);
                
                // Relleno de Combobox siguiente
                var salesOrgCombobox = [];
                
                for (var index1 = 0; index1 < dependentFieldsKeysList1.length; index1++) {
                    //console.log(fieldDependenciesCompanySalesOrg[index1].Company_Date__c);
                    if(fieldDependenciesCompanySalesOrg[index1].Company_Date__c == comboValue){
                        for (var index2 = 0; index2 < fieldDependenciesCompanySalesOrg[index1].Sales_Org_Date__c.length ; index2++){
                            salesOrgCombobox.push({'value': fieldDependenciesCompanySalesOrg[index1].Sales_Org_Date__c[index2], 'label': fieldDependenciesCompanySalesOrg[index1].Sales_Org_Date__c[index2]});
                            //console.log(fieldDependenciesCompanySalesOrg[index1].Sales_Org_Date__c[index2]);
                        }
                    }
                }
                
                salesOrgCombo.set("v.value", null);
                component.set("v.salesOrgCombobox", salesOrgCombobox);
                
            }
            
            else if(indexOfComboActive == 1){
                
                //Flow
                component.set("v.salesOrgSelected", comboValue);
                
                // Remover errores
                component.set("v.salesOrgError", false);
                component.set("v.salesOfficeError", false);
                
                var fieldDependenciesSalesOrgSalesOffice = component.get("v.fieldDependenciesSalesOrgSalesOffice");
                var dependentFieldsKeysList2 = Object.keys(fieldDependenciesSalesOrgSalesOffice);
                
                // Relleno de Combobox siguiente
                var salesOfficeCombobox = [];
                
                for (var index3 = 0; index3 < dependentFieldsKeysList2.length; index3++) {
                    //console.log(fieldDependenciesSalesOrgSalesOffice[index3].Sales_Org_Date__c);
                    if(fieldDependenciesSalesOrgSalesOffice[index3].Sales_Org_Date__c == comboValue){
                        for (var index4 = 0; index4 < fieldDependenciesSalesOrgSalesOffice[index3].Sales_Office_Date__c.length ; index4++){
                            salesOfficeCombobox.push({'value': fieldDependenciesSalesOrgSalesOffice[index3].Sales_Office_Date__c[index4], 'label': fieldDependenciesSalesOrgSalesOffice[index3].Sales_Office_Date__c[index4]});
                            //console.log(fieldDependenciesSalesOrgSalesOffice[index3].Sales_Office_Date__c[index4]);
                        }
                    }
                }
                
                salesOfficeCombo.set("v.value", null);
                component.set("v.salesOfficeCombobox", salesOfficeCombobox);
                
            }
            
        }
        
        else{
            
            //Flow
            component.set("v.salesOfficeSelected", comboValue);
            // Remover errores
            component.set("v.salesOfficeError", false);
            
        }
        
    },
    
    redirectToStore : function(component, event, helper){
        
        //window.open("https://www.w3schools.com");
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://www.neoris.com/"
        });
        urlEvent.fire();
        
    },
    
    saveOppDetails : function(component, event, helper){
        
        component.set("v.requiredError", false); // change
        
        var recordId = component.get("v.recordId");
        
        var companyCombo = component.find("companyId");
        var companyComboboxValue = companyCombo.get("v.value");
        
        var salesOrgCombo = component.find("salesOrgId");
        var salesOrgComboboxValue = salesOrgCombo.get("v.value");
        
        var salesOfficeCombo = component.find("salesOfficeId");
        var salesOfficeComboboxValue = salesOfficeCombo.get("v.value");
        
        var dateTimeValue = component.get("v.dateTime");
        
        /*var dateValue = component.get("v.date");
        var timeValue = component.get("v.time");*/
        
        console.log("requiredError: " + component.get("v.requiredError"));
		// Agregado
        var dateMin = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        var isValidDate = new Date(dateTimeValue);
        var inputDateCmp = component.find("today");
        
        //if(companyComboboxValue == null || salesOrgComboboxValue == null || salesOfficeComboboxValue == null || dateValue == null || timeValue == null){component.set("v.requiredError", true);}       
        if(companyComboboxValue == null || salesOrgComboboxValue == null || salesOfficeComboboxValue == null 
           || dateTimeValue == null || dateTimeValue < dateMin || isValidDate == "Invalid Date"){
            
            component.set("v.requiredError", true);
            
             if(isValidDate == "Invalid Date"){
                inputDateCmp.set("v.errors", [{message: $A.get("$Label.c.Qualification_Message_when_invalid_date") }]);
            } else if(dateTimeValue < dateMin){
                inputDateCmp.set("v.errors", [{message: $A.get("$Label.c.Qualification_Message_when_past_date") + " " + dateMin}]);
            }
            
        }       
        else{
            inputDateCmp.set("v.errors", null);
            helper.saveOppDetails1(component, recordId, companyComboboxValue, salesOrgComboboxValue, salesOfficeComboboxValue, dateTimeValue);
        }
        
    },
    
    showSpinner : function(component, componentId){ 
        component.set("v.Spinner", true); 
    },
    
    hideSpinner : function(component, event, helper){   
        component.set("v.Spinner", false);
    },
    
    validateFields: function(component, event, helper){
        
        var comboBox = event.getSource();
        
        if((comboBox.get("v.value") == undefined) || (comboBox.get("v.value") == null)) {
            
            switch(comboBox.get("v.name")){
                    
                case "company": 
                    component.set("v.companyError", true);
                    break;
                case "salesOrg": 
                    component.set("v.salesOrgError", true);
                    break;
                case "salesOffice": 
                    component.set("v.salesOfficeError", true);
                    break;
            }
            
        }
        
    },
    
    dateTimeChange : function (component, event, helper){
    	
    	var la = component.get("v.dateTime");
        console.log("dateTimeChange: "+la);
    
	}
    
})