({
    handleChange : function(component, event, helper) {
        // When an option is selected, navigate to the next screen
        var response = event.getSource().getLocalId();
        var boolResponse = (response == "Yes");
        component.set("v.response", response);
		component.set("v.accepted", boolResponse);
        var navigate = component.get("v.navigateFlow");
        navigate("NEXT");
    }
})