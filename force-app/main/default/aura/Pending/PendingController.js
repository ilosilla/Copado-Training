({
	doInit : function(component, event, helper) {
		component.set("v.firstScreen", true);
        component.set("v.lastScreen", true);
	},
    
    reloadStage : function(cmp){
        
        cmp.set("v.currentScreen", 1);
        cmp.set("v.firstScreen", true);
        cmp.set("v.lastScreen", false);
        cmp.set("v.successFailureFinalScreen", false);
        cmp.set("v.fieldsToUpdate", {});
        cmp.set("error", false);
        
    }
})