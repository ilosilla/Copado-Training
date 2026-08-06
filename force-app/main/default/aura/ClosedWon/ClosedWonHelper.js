({
    validateFields : function(cmp){
        // Recorre todos los input con el aura:id = 'fieldToValidate', si encuentra alguno
        cmp.set("v.error", false);
        var element = cmp.find('fieldToValidate');
        
        if(element != undefined){
            // Si solamente tiene un campo para verificar primero lo inserta en un array y despues hace lo mismo
            // que si tuviera varios elementos.
            
            if(!Array.isArray(element)){
                element = [element];
                
            }
            for(var i=0; i < element.length; i++){
                //console.log("element: " + element[i]);
                
                if(!element[i].get("v.validity").valid){
                    element[i].showHelpMessageIfInvalid();
                    cmp.set("v.error", true);
                }
            }  
        }
    },
    
    completeStage : function(cmp){
        var elementValue = cmp.get("v.comboValueReasonForClosure");
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        fieldsToUpdate.StageName = "Closed Won"; // ???
        
        switch(elementValue){
            case "E-commerce":
                fieldsToUpdate.Close_Mode__c = "E-commerce";
                break;
            case "In shop date":
                fieldsToUpdate.Close_Mode__c = "In shop date";
                break;
                
        }
        
        cmp.set("v.fieldsToUpdate", fieldsToUpdate);
        cmp.set("v.successFailureFinalScreen", true);
        
	}
})