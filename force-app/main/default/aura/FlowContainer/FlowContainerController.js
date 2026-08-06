({
    init : function(component, event, helper) {
        helper.startFlow(component);	
        //helper.setComponentTitle(component, event);
	}, // init    
    
    handleFlowStatusChange : function( component, event, helper ) {  
        var innerEvent = component.get("v.innerEvent");
        if (!innerEvent) {
            if ( event.getParam( 'status' ) === 'STARTED' || event.getParam( 'status' ) === 'FINISHED'  ) {
                helper.setComponentTitle(component, event);
                $A.get('e.force:refreshView').fire();
            }        
        } else {
            helper.setComponentTitle(component, event);            
            component.set("v.innerEvent", false);       
        }
    },

    handleRecordUpdated : function( component, event, helper ) {        
        var changeType = event.getParam('changeType');        
        if (changeType === 'CHANGED') {
            helper.startFlow( component );
        }
    }    
    
})