({
	getAccount : function(component, accountId) {
        var action = component.get("c.getAccount");
        action.setParams({
            accountId : accountId
        });            
        action.setCallback(this, response => this.setAccount(component, response));
        $A.enqueueAction(action);
			
	}, // getAccount

    setAccount : function(component, response) {                
		var state = response.getState();
        var response = response.getReturnValue();  
        if(state === "SUCCESS") {  
            if (response != null) {
                this.setScreenFields(component, response);
            } 
		}
    },
    
    setScreenFields : function(component, account) {
        if (account.IsPersonAccount) {
    		component.set("v.accountName", account.Name);
			component.set("v.street", account.PersonMailingStreet);
			component.set("v.city", account.PersonMailingCity);
			component.set("v.postcode", account.PersonMailingPostalCode);
			component.set("v.country", account.PersonMailingCountry);
			component.set("v.email", account.PersonEmail);
			component.set("v.phone", account.Phone);
            component.set("v.icon", "standard:person_account");
        } else {
    		component.set("v.accountName", account.Name);
			component.set("v.street", account.BillingStreet);
			component.set("v.city", account.BillingCity	);
			component.set("v.postcode", account.BillingPostalCode);
			component.set("v.country", account.BillingCountryCode);
			component.set("v.email", account.Business_Email__c);
			component.set("v.phone", account.Phone);
            component.set("v.icon", "standard:account");
        } // if PersonAccount
	}
})