({
	setResult : function(component, event, helper) {
		var result = event.target.id;        
		component.set("v.result", result);
        var navigate = component.get('v.navigateFlow');
      	navigate('NEXT');
	}
})