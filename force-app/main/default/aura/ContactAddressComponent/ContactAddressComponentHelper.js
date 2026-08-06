({
    ////////////////////////////////////////////////////////////
    // SERVER ACCESS
    ///////////////////////////////////////////////////////////

    saveAddress : function(component, address)  {
        component.set("v.submitting", true);
        component.set("v.addressFields", address);
        var action = component.get("c.testAddressUpsert");
        action.setParams({
            address : address
        });            
        action.setCallback(this, response => this.testAddressUpsertCallback(component, address, response));
        $A.enqueueAction(action);            
    },    

    ////////////////////////////////////////////////////////////
    // SERVER CALLBACKS
    ///////////////////////////////////////////////////////////

    testAddressUpsertCallback : function(component, address, response) {
        var state = response.getState();
        if (state === "SUCCESS") {              
            var action = component.get("c.saveAddress");
            action.setParams({
                address : address
            });            
            action.setCallback(this, response => this.saveAddressCallback(component, response));
            $A.enqueueAction(action);            
        } else {
            component.set("v.submitting", false);
            this.handleErrors(response.getError());
        }
    },

    saveAddressCallback : function(component, response) {
        var state = response.getState();
        if (state === "SUCCESS") {   
            var raddress = response.getReturnValue();
            this.forceFakeSubmit(component);
            //this.closeModal(component);            
        } else {
            this.handleErrors(response.getError());
        }
    },

    ////////////////////////////////////////////////////////////
    // INTERNAL METHODS
    ///////////////////////////////////////////////////////////
    
    handleErrors : function(errors) {
          // Configure error toast
          let toastParams = {
              title: "Unexpected Error",
              mode: 'sticky',
              message: "Unknown error", // Default error message
              type: "error"
          };

          // Pass the error message if any
          if (errors && Array.isArray(errors) && errors.length > 0) {
              toastParams.message = errors[0].message;
          }
  
          // Fire error toast
          let toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams(toastParams);
          toastEvent.fire();

      }, // handleErrors    
      
      /*
       * Submit with no changes to force the refresh of the components showing this address
       */
      forceFakeSubmit : function(component) {
        var eventFields = {};
        var name = component.find('Name').get("v.value");
        if (name != null) {
            eventFields["Name"] = name;
            component.find('recordForm').submit(eventFields);
        } else {
            this.closeModal(component);
        }
    },

    closeModal : function(component) {
        component.set("v.submitting", false);
        component.set("v.closing", true);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });          
            $A.get('e.force:refreshView').fire();
            })
            .catch(function (error) {});
    }
})