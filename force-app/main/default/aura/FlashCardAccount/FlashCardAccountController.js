({
	accountEvent : function(component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {		
            var id = component.get("v.currentRecord.AccountId__c");
            helper.getAccount(component, id);
        }
	}
    
    
})