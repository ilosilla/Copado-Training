({
    handleInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
    },
    
    handleClose: function (component, event, helper) {
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
    }
})