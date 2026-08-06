({
    handleInit : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var state = pageRef.state; // state holds any query params
        var base64Context = state.inContextOfRef; 
        if (base64Context.startsWith("1.")) {
            base64Context = base64Context.substring(2);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
        var objectName = addressableContext.attributes.objectApiName;
        var objectId = addressableContext.attributes.recordId;
        var actionName = addressableContext.attributes.actionName;
        component.set("v.accountId", objectId);
    }, 

    handleOnLoadAddress : function(component, event, helper) {
        component.set("v.addressLoading", false);
        var recordUi = event.getParam("recordUi");
        if (recordUi.createMode) {
            var accountId = component.get("v.accountId");
            component.find("ParentId").set("v.value", accountId);
            component.find("AddressType").set("v.value", "Shipping");
        }
    },

    handleOnSubmit : function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');
        fields.Id = component.get('v.recordId');
        if (!fields.Name) {
            fields.Name = 'Shipping Address';
        }
        helper.saveAddress(component, fields);        
        //component.find('recordForm').submit(fields);
    },

    handleOnSuccess : function(component, event, helper) {
        component.set("v.submitting", false);
        helper.closeModal(component);
    },

    handleOnError : function(component, event, helper) {
        component.set("v.submitting", false);
    },

    onCancelClick : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });
            })
            .catch(function (error) {
        });
        $A.get('e.force:closeQuickAction').fire();
    },

    onSaveClick : function(cmp, evt, hlpr) {
        var btn = cmp.find('submitButton').getElement();
        if (btn) {
            btn.click();
        }
    }    
    
})