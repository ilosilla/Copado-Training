({	
    doInit : function(component, event, helper) {
        var requestId = component.get("v.recordId");
		helper.getInstallationOrder(component, requestId);
	}, // doIinit 
    
    handleRecordUpdated : function(component, event, helper) {
        
    }
    
    
})