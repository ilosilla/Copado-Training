({
	checkUserAccess : function(component, helper) {
		
        var action = component.get("c.userHasAccess");
         action.setParams({
            recordId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            if(state === "SUCCESS"){
                
                console.log("Success: " + serverResponse);
                
                if(serverResponse){
                    helper.retrieveRecordTypes(component);
                    
                } else {
                    
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": $A.get("$Label.c.Insufficient_Permissions_Error"),
                        "message": $A.get('$Label.c.AccCMP_Permission'),
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                }
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
            else if(state === "ERROR"){
                    
                var errors = response.getError();
                console.log( errors );
                
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Something has gone wrong!",
                    "message": errors,
                    closeCallback: function() {
                        $A.get("e.force:closeQuickAction").fire();
                    }
                });
                
            }
            
        });
        
        $A.enqueueAction(action);
        
	},
    
    retrieveRecordTypes : function(component) {
		
        var action = component.get("c.getRecordTypes");
         action.setParams({
            recordId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            if(state === "SUCCESS"){
                
                console.log("Success: " + JSON.stringify(serverResponse));
                
                var recordTypeOptions = [];
                
                for(let x in serverResponse){
                    recordTypeOptions.push({'label': x, 'value': serverResponse[x]});
                }
                
                if(recordTypeOptions.length == 0){
                    component.find('notifLib').showNotice({
                        "variant": "warning",
                        "header": $A.get("$Label.c.Warning"),
                        "message": $A.get("$Label.c.AccRecChange_NoRecTypeAvaliable"),
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                    
                } else {
                    component.set("v.recordTypeOptions", recordTypeOptions);
                	component.set("v.disableButtons", false);
                }
                
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
            else if(state === "ERROR"){
                    
                var errors = response.getError();
                console.log( errors );
                
                component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": errors,
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                
            }
            
        });
        
        $A.enqueueAction(action);
        
	},
    
    isConvertionPossible : function(component, helper, recordTypeId) {
		component.set("v.message", $A.get("$Label.c.AccRecChange_Checking"));
        
        var action = component.get("c.checkIfPossible");
         action.setParams({
            recordId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            if(state === "SUCCESS"){
                
                console.log("Success: " + JSON.stringify(serverResponse));
                
                if(serverResponse.hasOwnProperty('error')){
                    
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": $A.get("$Label.c.AccRecChange_NotPossible"),
                        "message": serverResponse.error,
                        
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                    
                } else {
                    
                    helper.convertAccount(component, helper, recordTypeId);
                }
                
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
            else if(state === "ERROR"){
                    
                var errors = response.getError();
                console.log( errors );
                
                component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": errors,
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                
            }
            
        });
        
        $A.enqueueAction(action);
        
	},
    
    convertAccount : function(component, helper, recordTypeId) {
        component.set("v.message", "Converting...");
        
        var recordId = component.get("v.recordId");
        
        var action = component.get("c.convertAccount");
        action.setParams({
            recordId : recordId,
            recordTypeId : recordTypeId
        });
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            if(state === "SUCCESS"){
                
                console.log("Success: " + JSON.stringify(serverResponse));
                
                if(serverResponse.hasOwnProperty("error")){
                    
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": serverResponse.error,
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                    
                } else {
                    component.set("v.message", 'Redirecting...');
                    
                    window.setTimeout(
                        $A.getCallback(function() {
                            
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": $A.get("$Label.c.AccRecChange_Success"),
                                "mode": "sticky",
                                "type": "success",
                                "message": $A.get("$Label.c.AccRecChange_ToComplete")
                            });
                            toastEvent.fire();
                            
                            var navService = component.find("navService");
                            console.log("navService: " + JSON.stringify(navService));
                            console.log("recordId: " + recordId);
                            var pageReference = {    
                                "type": "standard__recordPage",
                                "attributes": {
                                    "recordId": recordId,
                                    "objectApiName": "Account",
                                    "actionName": "edit"
                                }
                            };
                            
                            /*var pageReference = {    
                                "type": "standard__webPage",
                                "attributes": {
                                    "url": "/lightning/r/Account/" + recordId + "/edit"
                                }
                            };*/
                            
                            navService.navigate(pageReference, true);
                            
                            
                        }), 1500
                    );
                }
                
            }
            
            else if(state === "INCOMPLETE"){
                
                console.log("STATUS INCOMPLETE");
                
            }
            
            else if(state === "ERROR"){
                    
                var errors = response.getError();
                console.log( errors );
                
                component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": errors,
                        closeCallback: function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    });
                
            }
            
        });
        
        $A.enqueueAction(action);
        
	},
    
})