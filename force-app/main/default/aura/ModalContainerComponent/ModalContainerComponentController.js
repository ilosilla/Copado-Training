({
    onModalCancel : function(component, event, helper) {
        component.set("v.isActive", false);
    },
    onModalSave : function(component, event, helper) {
        var cmpCommand = component.getEvent("cmpCommand");
        cmpCommand.setParams({
            "command" : "SAVE"
        });
        cmpCommand.fire();
        alert("Clic");

    },

})