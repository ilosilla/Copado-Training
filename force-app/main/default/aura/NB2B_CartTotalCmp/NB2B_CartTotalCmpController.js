({
    getTotalAmount : function(component, event, helper) {
	var action = component.get('c.getCartTotal');
        action.setParams({
            recordId : component.get('v.recordId')
        });            
        action.setCallback(this, function(response) {
            var state = response.getState();
            var wrapper = response.getReturnValue();
            if (state === "SUCCESS") {
                //if(wrapper.TotalProductCount = 0){
					component.set('v.showTotals', true);                    
                //}
                var totalAux;
                if(wrapper.amount && wrapper.amount > 0){
                    totalAux = wrapper.amount;
                }else{
                   totalAux = 0; 
                }
                if(wrapper.language != null){
                    component.set('v.userLanguage', wrapper.language.replace("_", "-"));
                }else{
                    component.set('v.userLanguage', 'en-UK');
                }
                component.set('v.total',(Math.floor(totalAux * 100)/100).toLocaleString(component.get('v.userLanguage')));
				component.set('v.currencyCart', wrapper.currencyCart);
                /*if(wrapper.deliveryCharges != null){
                    component.set('v.showDeliveryCharges', true);                   
					component.set('v.deliveryCharges', wrapper.deliveryCharges);                    
                }*/

                //component.set('v.userLanguage', wrapper.language);
        	}else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "There was an error getting the total amount"
                });
    			toastEvent.fire();
            } 
        });
        $A.enqueueAction(action);     
    }
})