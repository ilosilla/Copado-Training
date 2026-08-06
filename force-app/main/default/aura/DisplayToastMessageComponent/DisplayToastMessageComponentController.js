({
	displayToastMessage : function(component, event, helper) {
        if(component.get("v.IsRedirectToSObjectRecord")){
            var navigate = component.get("v.navigateFlow");
            navigate("FINISH");
        }
        else{
            var navigate = component.get("v.navigateFlow");         
            navigate("NEXT");
        }
        
        if(component.get("v.message") != null){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : component.get("v.title"),
                message: component.get("v.message"),
                type: component.get("v.type")
            });
            toastEvent.fire();             
        }
                
        // Navigate back to the record view
        var navigateEvent = $A.get("e.force:navigateToSObject");
        navigateEvent.setParams({ "recordId": component.get('v.recordId') });
        navigateEvent.fire();
                
	}
})