({
	doInit : function(component, event, helper) {
		var action = component.get("c.getCartItemsList");
        var recordId = component.get('v.cartId') != null ? component.get('v.cartId') : component.get('v.recordId');
        action.setParams({
            recordId : recordId
        });            
        //action.setCallback(this, response => this.showButton(component, response));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var wrapper = response.getReturnValue();
            if (state === "SUCCESS") {
                component.set('v.showList', wrapper.isCorrect);
                component.set('v.cartItem', wrapper);
                if(wrapper.showWarning != null){
	                component.set('v.showDateWarning', wrapper.showWarning);                    
                }
                component.set('v.deliveryDate', $A.localizationService.formatDate(wrapper.deliveryDate));
                
            }else{
                component.set('v.showList', false);
            } 
        });
        $A.enqueueAction(action);     
	}
})