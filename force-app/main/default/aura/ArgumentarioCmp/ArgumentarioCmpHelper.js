({
    
	getOpportunityDetails : function(cmp, recordId) {
        
        cmp.set("v.spinner", true);
        
        var action = cmp.get("c.getOpportunity");        
        action.setParams({'recordId' : recordId});
        
        action.setCallback(this, function(response){
            
            if(response.getState() === "SUCCESS"){
                
                cmp.set("v.opportunity",response.getReturnValue());                
                cmp.set("v.spinner", false);
                
            }
            
            else{
                
                alert("Error getting the opportunity details");
                
            }
            
        });
        
        $A.enqueueAction(action);
        
		
	},
    
    saveOpportunityDetails : function(cmp) {
        
        cmp.set("v.spinner", true);
        
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        var accountFieldsToUpdate = cmp.get("v.accountFieldsToUpdate");
        console.log("fieldsToUpdate: " + JSON.stringify(fieldsToUpdate));
        
        var action = cmp.get("c.saveOpportunity");
        
        action.setParams({'recordId' : cmp.get("v.recordId"),
                          'jsonObject' : JSON.stringify(fieldsToUpdate),
                         'jsonAccount' : JSON.stringify(accountFieldsToUpdate)});
        
        action.setCallback(this, function(response){
            
            if(response.getState() === "SUCCESS"){
                
                console.log("EXITO al guardar la oportunidad");
                $A.get('e.force:refreshView').fire();
                
                // resetea los campos a actualizar
                cmp.set("v.fieldsToUpdate", {});
                cmp.set("v.accountFieldsToUpdate", {});
                
                cmp.set("v.spinner", false);
            }
            
            else{
                
                alert("Error while saving opportunity details");
                
            }
            
        });
        
        $A.enqueueAction(action);
		
	}
    
})