({
    getRecord : function(cmp) {
        
        // obtener registro correspondiente
        var action = cmp.get("c.searchRecord");
        action.setParams({'recordId' : cmp.get('v.recordId')});
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if(state == "SUCCESS"){
                
                cmp.set('v.opportunityObject', response.getReturnValue());
                
                
            }
            
            else {console.log("Unknown error");}
            
        });
        
        $A.enqueueAction(action);
        
    },
    
    getPicklistValuesFromField : function(cmp, attributeName, objectApiName, fieldName){
        
        // obtener valores de picklist "Satisfaction__c" para asignar al atributo satisfactionCombobox
        var action = cmp.get("c.getPickListValues");
        action.setParams({'objectApiName' : objectApiName, 'fieldName' : fieldName});
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if(state == "SUCCESS"){
                
                cmp.set('v.' + attributeName, response.getReturnValue());
                
            }
            
            else {console.log("Unknown error");}
            
        });
        
        $A.enqueueAction(action);
        
    }
    
    
})