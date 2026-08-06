({
    getLabel : function(component) {
        var aux = this;
        var recordId = component.get("v.recordId");   
        if (recordId != null) {
            this.getLabelAjax(component,recordId).then(function(result) {
                if (result.labelAPI != null) {
                    component.set("v.ready", true);
                    component.set("v.stageName", result.stageLabel);
                    component.set("v.labelName", result.labelAPI);
                    var labelReference = $A.getReference("$Label.c." + result.labelAPI);
                    component.set("v.labelReference", labelReference);
                } else {
                    component.set("v.labelReference", null);
                }
            }).catch(function (err) {
                console.log(err);
                aux.showErrorMessage(component, "Error!", err.message);
            });  
        }
    },

    getLabelAjax : function(component, recordId) {
        var action = component.get("c.getLabel");
        action.setParams({
            recordId: recordId
        });
        return this.returnPromiseAjax(action);
    },
    /********* Global methods *************/
    showErrorMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "error"
        });
        toastEvent.fire();
    },
    showWarningMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "warning"
        });
        toastEvent.fire();
    },
    showSuccessMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "success"
        });
        toastEvent.fire();
    },
    returnPromiseAjax : function(action) {
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS"){
                    resolve(response.getReturnValue());
                } else if(state === "ERROR") {
                    var errors = action.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            // System Error
                            reject(errors[0]);
                        } else if (errors[0] && errors[0].pageErrors) {
                            // DML Error
                            // （This sample code is corner-cutting. It does not consider the errors in multiple records and fields.）
                            reject(errors[0].pageErrors[0]);
                        }
                    }
                }
            });         
            $A.enqueueAction(action);
        });
    }
})