({
	setClosedWon : function(component, event, helper) {
		component.set("v.gotoClosedWon", true);
        var navigate = component.get('v.navigateFlow');
      	navigate('NEXT');
	},
    setClosedLost : function(component, event, helper) {        
		component.set("v.gotoClosedLost", true);
        var navigate = component.get('v.navigateFlow');
      	navigate('NEXT');
	}
})