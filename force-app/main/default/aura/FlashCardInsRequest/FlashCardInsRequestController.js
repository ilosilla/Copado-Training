({
	init : function(component, event, helper) {
		var oppId = component.get("v.recordId");
		helper.getRequest(component, oppId);
    }, // init    
	reload : function(component, event, helper) {
        var src = event.getSource().toString(); 
        if (src.includes('flowRuntimeForQuickAction')) {
            var oppId = component.get("v.recordId");
            helper.getRequest(component, oppId);
        }
    }    
})