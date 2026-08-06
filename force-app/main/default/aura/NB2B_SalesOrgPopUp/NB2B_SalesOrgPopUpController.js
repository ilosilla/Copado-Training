({
	doInit : function(component, event, helper) {
		var action = component.get("c.getSalesOrgList");        
        
        action.setCallback(this, function(response) {
            component.set('v.loading', false);
            var state = response.getState();
            var wrapper = response.getReturnValue();
            var requestFailed = false;
            if (state === "SUCCESS") {
                console.log('NB2B_SalesOrgPopUpController - doInit() - wrapper:', wrapper);
                component.set('v.salesList', wrapper);
            }else{
                requestFailed = true;
            } 
            helper.managePopUpVisibility(component, requestFailed);
        });
        $A.enqueueAction(action);     
	},
    onValueChange : function(component, event, helper) {
       var salesList = component.get('v.salesList');
       var salesId = component.get('v.salesId');
        for(var i =0; i< salesList.length; i++){
            if(salesList[i].Id == salesId){
                console.log('Save: ' + salesId);
                helper.setContactSalesOrg(component, salesId);
                helper.setSessionSalesOrg(salesList[i]);
                component.set('v.showSelector', false);
                break;
            }
        }
	}
})