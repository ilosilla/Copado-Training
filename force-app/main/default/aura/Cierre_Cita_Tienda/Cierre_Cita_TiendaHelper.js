({
    
    getFieldDependencies: function(component, recordId, controllerField, dependentField){
        
        component.set("v.Spinner", true);
 		
        var action = component.get("c.getDependentMap");        
        action.setParams({
            'recordId' : recordId,
            'controlFieldApiName': controllerField,
            'dependentFieldApiName': dependentField
        });
        
        action.setCallback(this, function(response) {
            
            if (response.getState() === "SUCCESS") {

                var serverResponse = response.getReturnValue();
                var dependenciesList;
                console.log("serverResponse: " + JSON.stringify(serverResponse ));
                // Dependencia Company_Date__c - Sales_Org_Date__c
                if(controllerField == 'Company_Date__c'){
                    
                    dependenciesList = [];
                    var companyCombobox = [];
                    
                    for (var singlekey1 in serverResponse) {
                        
                        dependenciesList.push({'Company_Date__c':singlekey1, 'Sales_Org_Date__c':serverResponse[singlekey1]});
                        companyCombobox.push({'value': singlekey1, 'label': singlekey1});
                        
                    }
                    
                    component.set("v.fieldDependenciesCompanySalesOrg", dependenciesList);                    
                    component.set("v.companyCombobox", companyCombobox);
                    
                }
                // Dependencia Sales_Org_Date__c - Sales_Office_Date__c
                else if(controllerField == 'Sales_Org_Date__c'){
                    
                    dependenciesList = [];
                    var salesOrgCombobox = [];
                    
                    for (var singlekey2 in serverResponse) {
                        
                        dependenciesList.push({'Sales_Org_Date__c':singlekey2, 'Sales_Office_Date__c':serverResponse[singlekey2]});
                        salesOrgCombobox.push({'value': singlekey2, 'label': singlekey2});
                        
                    }
                    
                    component.set("v.fieldDependenciesSalesOrgSalesOffice", dependenciesList);
                    component.set("v.salesOrgCombobox", salesOrgCombobox);
                    
                }
                
                component.set("v.Spinner", false);
                
            }
            
            else{
                
                alert('Error');
                
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
    saveOppDetails1 : function(component, recordId, companyComboboxValue, salesOrgComboboxValue, salesOfficeComboboxValue, dateTimeValue){
        
        component.set("v.requiredError", true); //changed
        component.set("v.Spinner", true); // changed
        
        console.log('dateTimeValue prueba' + dateTimeValue);
        
        var action = component.get("c.saveRecord");
        action.setParams({
            'recordId' : recordId,
            'companyComboboxValue' : companyComboboxValue,
            'salesOrgComboboxValue' : salesOrgComboboxValue,
            'salesOfficeComboboxValue' : salesOfficeComboboxValue,
            'dateTimeValue' : dateTimeValue
        });
        
        action.setCallback(this, function(response){
            
            if (response.getState() === "SUCCESS") {

                component.set("v.requiredError", false); // changed
                component.set("v.Spinner", false); // changed
                
                $A.get('e.force:refreshView').fire();                
                
                console.log("SUCCESS Cita Tienda");
                
                // Changed
                var evt = component.getEvent("childCmpChangeScreen");
                evt.setParams({
                    "action":"Next", "companyComboboxValue": companyComboboxValue, 
                    "salesOrgComboboxValue": salesOrgComboboxValue, 
                    "salesOfficeComboboxValue": salesOfficeComboboxValue,
                    "dateCita": dateTimeValue
                });
                evt.fire();
                
            }

            else{
                
                alert('Error saving opportunity details');
                
            }
            
        });
        
        $A.enqueueAction(action);
        
    },
    
    loadTimeCombo : function (component){
        
        var timeArray = [];
        var timeLabel, timeValue;
		
        for(var num=8; num<19; num++){            
            
            //timeArray.push({'value': (num < 12) ? num + ':00 AM' : (num > 12) ? (num - 12) + ':00 PM' : num + ':00 PM', 'label': num + ':00'});
            //if(num < 19)({'value': (num < 12) ? num + ':30 AM' : (num > 12) ? (num - 12) + ':30 PM' : num + ':30 PM', 'label': num + ':30'});
            timeArray.push({'value': num + ':00', 'label': num + ':00'});
            if(num < 19)({'value': num + ':30', 'label': num + ':30'});
            
        }
        
        console.log(timeArray);        
        component.set('v.timeCombobox', timeArray);
        
    }
    
})