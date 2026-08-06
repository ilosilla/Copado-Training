({
    onInit : function(component, event, helper) {
        helper.prepareConversion(component, component.get('v.recordId'));
    }, // onInit

    saveClick : function(component, event, helper) {
        if (helper.validateLead(component)) {            
            helper.convertLead(component);
        }
    },
    
    editLeadClick :function(component, event, helper) {
        var actionAPI = component.find("quickActionAPI");
        var args = { actionName :"Lead.EditWebLead" };
        actionAPI.selectAction(args).then(function(result) {
            // Action selected; show data and set field values        
        }).catch(function(e) {
            if (e.errors) {
                // If the specified action isn't found on the page, 
                // show an error message in the my component 
            }
        });                
    },

    cancelClick : function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
    },
    
    newAccountBoxChanged : function(component, event, helper) {
        var create = component.get("v.createNewAccount");
        if (create) {            
            component.set("v.theLead.AccountId__c", '');
            component.set("v.createNewContact", false);
            helper.clearAccountField(component);
        } else {
            helper.setAccountProperties(component);
        }
    },

    newContactBoxChanged : function(component, event, helper) {
        var checked = component.get("v.createNewContact");
        if (checked) {
            component.set("v.contactId", '');
        }
        helper.setAccountProperties(component);
    },

    onChangeAccount :  function(component, event, helper) {
        helper.readAccountInfo(component);
    },

    closeMessage : function(component, event, helper) {
        component.set("v.errorList", []);
    },

    dontCreateBoxChanged : function(component, event, helper) {
        var checked = component.get("v.dontCreateOpp");
        component.set("v.disableOpportunity", checked);        
    }

})