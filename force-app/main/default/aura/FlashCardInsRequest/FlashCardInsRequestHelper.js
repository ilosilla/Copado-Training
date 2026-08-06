({
	getRequest : function(component, oppId) {
        var action = component.get("c.getRequest");
        action.setParams({
            opportunityId : oppId
        });            
        action.setCallback(this, response => this.setData(component, response));
        $A.enqueueAction(action);			
	}, // getAccount
 
    setData : function(component, response) {                
        var state = response.getState();
        var list = response.getReturnValue();                

        if(state === "SUCCESS") {  
			this.setScreenFields(component, list);
        } 
        // Server might return exceptionType NotEnabledException in which
        // case we leave the componetn invisible
    },    
    
    setScreenFields : function(component, list) {
        component.set("v.visible", "true");  
		if (list && list.length > 0) {
            component.set("v.request", list[0]);
            if (list.length > 1) {            
                component.set("v.installer", list[1]);        
            }
        } else {
            
        }
    } // PersonAccount
})