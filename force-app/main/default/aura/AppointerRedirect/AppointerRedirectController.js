({
	doInit : function(component, event, helper) {
		var url = component.get('v.url');
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": url
        });
        urlEvent.fire();
	}
})