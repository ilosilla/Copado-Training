({
	getOppContactRoleErrors : function(component) {
		component.set("v.spinner", true);
        component.set("v.disableButtons", true);
        
        var action = component.get("c.returnOppContactRolesErrors");
        
        action.setParams({
            recordId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var serverResponse = response.getReturnValue();           
            if(state === "SUCCESS"){
                if(serverResponse.length > 0 ){
                    component.set("v.showTable", true);
                    component.set("v.oppContactRoles", serverResponse);
                } else{
                    component.set("v.showTable", false);
                }
                component.set("v.spinner", false);
                component.set("v.disableButtons", false);
            }            
            else if(state === "INCOMPLETE"){                
                console.log("STATUS INCOMPLETE");                
            }            
                else if(state === "ERROR"){                    
                    var errors = response.getError();
                    console.log(errors);                    
                }            
        }); 
        $A.enqueueAction(action);
	},
    retrySendToSAP : function(component, helper, oppActorId) {
        component.set("v.disableButtons", true);
        
        var action = component.get("c.retry");
        
        action.setParams({
            recordId : oppActorId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            console.log("serverResponse: " + JSON.stringify(serverResponse));
            console.log("serverResponse: " + serverResponse);
            
            if(state === "SUCCESS"){
                
                if(serverResponse == "" ){
                    component.set("v.screenMessage", $A.get("$Label.c.ErrorCMP_CheckLater"));
                    component.set("v.showTable", false);
                    $A.get('e.force:refreshView').fire();
                    
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: 'Error',
                        Title: 'Error during the retry proccess',
                        message: serverResponse
                        
                    });
                    toastEvent.fire();
                    
                }
                component.set("v.disableButtons", false);
            }            
            else if(state === "INCOMPLETE"){                
                console.log("STATUS INCOMPLETE");                
            }            
                else if(state === "ERROR"){                    
                    var errors = response.getError();
                    console.log(errors);                    
                }            
        }); 
        $A.enqueueAction(action);
	}
})