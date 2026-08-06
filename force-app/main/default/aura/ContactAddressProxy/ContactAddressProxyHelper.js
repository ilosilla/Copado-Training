({
    ////////////////////////////////////////////////////////////
    // SERVER ACCESS
    ///////////////////////////////////////////////////////////
    syncSAPAddresses : function(component)  {
        component.set("v.syncing", true);
        component.set("v.text", $A.get("$Label.c.addr_sync_intro"));
        var accountId = component.get("v.recordId");
        var action = component.get("c.syncSAPAddresses");
        action.setParams({
            accountId : accountId
        });            
        action.setCallback(this, response => this.syncSAPAddressesCallback(component, response));
        $A.enqueueAction(action);            
    },    

    ////////////////////////////////////////////////////////////
    // SERVER CALLBACKS
    ///////////////////////////////////////////////////////////

    syncSAPAddressesCallback : function(component, response) {
        component.set("v.syncing", false);
        var state = response.getState();
        if (state === "SUCCESS") {               
            var data = response.getReturnValue();                
            this.notifySyncResults(component, data);            
        } else {
            this.handleErrors(component, response.getError());
        }
    },

    ////////////////////////////////////////////////////////////
    // INTERNAL METHODS
    ///////////////////////////////////////////////////////////

    handleErrors : function(component, errors) {
        // Pass the error message if any
        var message = $A.get("$Label.c.addr_sync_error");        
        if (errors) {
            var fieldErrors = errors[0].fieldErrors;  
            if (fieldErrors && Array.isArray(fieldErrors.Name) && fieldErrors.Name.length > 0) {
                message = message.replace('{0}', fieldErrors.Name[0].message);
            } else if (Array.isArray(errors) && errors.length > 0) {
                message = message.replace('{0}', errors[0].message);
            }
        }
        component.set("v.text", message);
    }, // handleErrors 
    
    notifySyncResults : function(component, data) {
        component.set('v.syncable', data.syncable);
        if (data.syncable) {
            if (Array.isArray(data.addresses) && data.addresses.length >  0) {
                var message = $A.get("$Label.c.addr_sync_result");
                message = message.replace('{0}', data.addresses.length);
                component.find('notifLib').showToast({
                    "variant": "info", 
                    "title": $A.get("$Label.c.dict_success") + "!",
                    "message": message
                });   
            } 
            $A.get('e.force:refreshView').fire();       
        } else {
            component.set("v.text", $A.get("$Label.c.addr_not_syncable"));
        }
    }

})