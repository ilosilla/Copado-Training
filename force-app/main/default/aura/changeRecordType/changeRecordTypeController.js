({
	doInit : function(component, event, helper) {
		helper.checkUserAccess(component, helper);
        
	},
    
    handleCancel : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
    
    handleNext : function(component, event, helper) {
		var radioGroup = component.find("recordTypeRadio");
        
        if(radioGroup != undefined){
            if( !radioGroup.get("v.validity").valid){
                radioGroup.showHelpMessageIfInvalid();
                
            } else {
                var selectedOption = radioGroup.get("v.value");
                component.set("v.message", "Converting...");
                component.set("v.disableButtons", true);
                
                helper.isConvertionPossible(component, helper, selectedOption);
                
            }
        }
        
        
	},
})