({
	doInit : function(component, event, helper) {
        helper.getOppContactRoleErrors(component);
        
	},
    
    handleRefresh : function(component, event, helper) {
        helper.getOppContactRoleErrors(component);
        $A.get('e.force:refreshView').fire();
	},
    
    handleRetry : function(component, event, helper) {
		component.set("v.disableButtons", true);
        let oppContactRoleId = event.getSource().get("v.name")
        
        helper.retrySendToSAP(component, helper, oppContactRoleId);
        
	}
})