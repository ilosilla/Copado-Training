({
	onInit : function(component, event, helper) {
        var json = component.get("v.installersJSON");
		var installers = helper.installersToCombo(json);
        component.set("v.installers", installers);
        if (installers.length == 1) {
            component.set("v.installer", installers[0].value);
        }
        var name = component.get("v.installationName");        
        if (!name) {
            var opName = component.get("v.opportunityName");            
            component.set("v.installationName", helper.buildDefaultName(opName));
        }
        // Set the validate attribute to a function that includes validation logic
        component.set('v.validate', ()=>helper.validate (component));	                
	}, // onInit   
    
	handleChange: function (component, event) {
        // This will contain the string of the "value" attribute of the selected option
        var selectedOptionValue = event.getParam("value");
        component.set("v.installer", selectedOptionValue);
    }    
})