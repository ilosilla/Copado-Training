({
    setTitles : function(component) {
        var priceRequest = component.get("v.priceRequest");
        var title = $A.get('$Label.c.prequest_pricerequest');
        var subtitle = $A.get('$Label.c.dict_no') + ' ' + $A.get('$Label.c.prequest_pricerequest');
        if (priceRequest != null) {
            if (priceRequest.Status__c == 'NEW') {
                if (priceRequest.TotalItems__c == 0) {
                    subtitle = $A.get('$Label.c.prequest_no_items');
                } else {
                    subtitle = $A.get('$Label.c.prequest_items_waiting');
                }
            }
            if (priceRequest.Status__c == 'PENDING') {
                if (priceRequest.WaitingItems__c > 0) {
                    subtitle = $A.get('$Label.c.prequest_items_waiting');
                } else {
                    subtitle = $A.get('$Label.c.prequest_items_waiting_approval');
                }
            }
            if (priceRequest.Status__c == 'FINISHED') {
                subtitle = $A.get('$Label.c.prequest_items_app_rej');
            }
        }
        component.set("v.titleFlashCard", title);
        component.set("v.subtitleFlashCard", subtitle);
    },
    /************************* AJAX CALLS ********************************/
    getAllDataAjax : function(component, opportunityId) {
        var action = component.get("c.getAllData");
        action.setParams({
            opportunityId: opportunityId
        });
        return this.returnPromiseAjax(action);
    },
    showErrorMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            title: title,
            message: body,
            type: "error"
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