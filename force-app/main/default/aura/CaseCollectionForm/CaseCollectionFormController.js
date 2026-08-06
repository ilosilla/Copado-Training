({
    handleInit : function(component, event, helper) {
        var recordId = component.get('v.recordId');
        alert("esto es el onload del componente aura " + recordId);
    },

    handleCancel : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });
            })
            .catch(function (error) {
        });
        //$A.get('e.force:closeQuickAction').fire();
    }
})