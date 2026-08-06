({
	getAccountErrors : function(component) {
		component.set("v.spinner", true);
        component.set("v.disableButtons", true);
        
        var action = component.get("c.returnAccErrors");
        
        action.setParams({
            recordId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            console.log("serverResponse: " + JSON.stringify(serverResponse));
            
            if(state === "SUCCESS"){
                
                if(serverResponse.length > 0 ){
                    
                    if(serverResponse.length == 1 && serverResponse[0].Sap_Status__c == 'Undefined' && 
                       serverResponse[0].Reason_of_creation__c == 'New Account'){
                        
                        var salesRecordData = component.find("recordData_SalesRel");
                        salesRecordData.set("v.recordId", serverResponse[0].Id);
                        salesRecordData.reloadRecord();
                        component.set("v.showSendingMessage", true);
                        
                    } else {
                        component.set("v.accountSapErrors", serverResponse);
                        component.set("v.showTable", true);
                    }
                    
                } else{
                    component.set("v.showTable", false);
                }
                
                component.set("v.spinner", false);
                component.set("v.disableButtons", false);
                $A.get('e.force:refreshView').fire();
                
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
    
    retrySendToSAP : function(component, helper, salesRelId) {
        component.set("v.disableButtons", true);
        
        var action = component.get("c.retry");
        
        action.setParams({
            recordId : salesRelId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            console.log("serverResponse: " + JSON.stringify(serverResponse));
            console.log("serverResponse: " + serverResponse);
            
            if(state === "SUCCESS"){
                
                if(serverResponse == "" ){
                    component.set("v.spinner", true);
                    $A.get('e.force:refreshView').fire();
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: $A.get("$Label.c.Error") ,
                        Title: $A.get("$Label.c.Error_during_SAP_Synchronization"),
                        message: serverResponse
                        
                    });
                    toastEvent.fire();
                    
                }
                
                helper.getAccountErrors(component);
                
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