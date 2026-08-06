({
	getInstallationOrder : function(cmp, requestId) {
        var action = cmp.get("c.getOrderFromRequest");
        action.setParams({
            requestId : requestId
        });            
        action.setCallback(this, function(response) {                
            var state = response.getState();
            var response = response.getReturnValue();                
            if(state === "SUCCESS") {  
                if (response != null) {
                	cmp.set("v.installationOrder", response);                    
                } /*else {
					var cmpTarget = cmp.find('order-container');
        			$A.util.addClass(cmpTarget, 'slds-hide');        
                }*/
            }                
        });            
        $A.enqueueAction(action);
	} // getInstallationOrder
})