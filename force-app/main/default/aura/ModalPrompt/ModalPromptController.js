({
    handleInit : function(component, event, helper) { 
        var variant = component.get("v.variant");
        if (variant.toLowerCase() == 'deletefile') {
            component.set("v.title", $A.get("$Label.c.dict_deleteFileTitle"));
            component.set("v.text", $A.get("$Label.c.dict_deleteFileText"));
            component.set("v.trueButton", $A.get("$Label.c.dict_delete"));
            component.set("v.falseButton", $A.get("$Label.c.dict_button_cancel"));
        } else if (variant.toLowerCase() == 'yesno') {
            component.set("v.trueButton", $A.get("$Label.c.dict_yes"));
            component.set("v.falseButton", $A.get("$Label.c.dict_no"));
        } else {
            component.set("v.trueButton", "OK");
            component.set("v.falseButton", $A.get("$Label.c.dict_button_cancel"));
        }
    },

    closeModal : function(component, event, helper) { 
        component.set("v.isOpen", false);
    },
    
    userClickedOK : function(component, event, helper) {
        var command = component.get("v.command");
        var cmpCommand = component.getEvent("cmpCommand");
        cmpCommand.setParams({
            "command" : command,
            "arg" : true });
        cmpCommand.fire();   
    },

    userClickedCancel : function(component, event, helper) {
        var command = component.get("v.command");
        var cmpCommand = component.getEvent("cmpCommand");
        cmpCommand.setParams({
            "command" : command,
            "arg" : false });
            cmpCommand.fire();       
        }
})