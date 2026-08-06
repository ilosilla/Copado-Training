({
    handleCancel : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });
            $A.get('e.force:closeQuickAction').fire();
            $A.get('e.force:refreshView').fire();    
            })
        .catch(function (error) {
        });
        //$A.get('e.force:closeQuickAction').fire();
    },

    handleClose : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });
            $A.get('e.force:closeQuickAction').fire();
            $A.get('e.force:refreshView').fire();    
        })
        .catch(function (error) {
        });
    }

})