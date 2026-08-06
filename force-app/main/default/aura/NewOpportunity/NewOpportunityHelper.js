({
    
    validateFields : function(cmp, currentScreen){
        
        // Recorre todos los input con el aura:id = 'fieldToValidate', si encuentra alguno
        cmp.set("v.error", false); 
        var element = cmp.find('fieldToValidate');
        if(element !== undefined){
            if(!element.get("v.validity").valid){
                element.showHelpMessageIfInvalid();
                cmp.set("v.error", true);
                
            }else{
                cmp.set("v.error", false);
                
                switch(element.get("v.value")){
                        
                    case "Yes":
                        cmp.set("v.finalMessage", "Contacted");
                        this.completeStage(cmp);
                        break;
                        
                    case "1Missed":
                        cmp.set("v.finalMessage", "TaskCreated");
                        this.manageMissedCalls(cmp, 1);
                        break;
                        
                    case "2Missed":
                        cmp.set("v.finalMessage", "OpportunityLost");
                        this.discardOpportunity(cmp);
                        this.manageMissedCalls(cmp, 2);
                        break;
                        
                }
            }
        }
        

    },
    
    completeStage : function(cmp){
        
        cmp.set("v.successFailureFinalScreen", true);
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        fieldsToUpdate.StageName = "Qualification";
        
    },
    
    discardOpportunity : function(cmp){
        
        cmp.set("v.successFailureFinalScreen", true);
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        fieldsToUpdate.Close_Mode__c = "Not contacted";
        fieldsToUpdate.StageName = "Closed Lost";
        
    },
    
    manageMissedCalls : function(cmp, numberOfCalls){
        
        var action = cmp.get("c.manageMissedCalls");
        var opportunity = cmp.get("v.newOpportunity");
        
        action.setParams({'recordId' : opportunity.Id,
                          'numberOfCalls' : numberOfCalls});
        
        action.setCallback(this, function(response){
            
            if(response.getState() === "SUCCESS"){
                
                if(numberOfCalls == 1){
                    
                    console.log(response.getReturnValue());
                    cmp.set("v.taskCreatedId", response.getReturnValue());
                    
                }
                // edit 15-03
                if(response.getReturnValue() != 'Success'){
                    let toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                } else {
                    let toastEventSuccess = $A.get("e.force:showToast");
                    toastEventSuccess.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": 'Email has been sent.'
                    });
                    toastEventSuccess.fire();
                }
            }
            
            else{
                
                alert("Error managing calls");
                
            }
            
        });
        
        $A.enqueueAction(action);
        
    },
    
})