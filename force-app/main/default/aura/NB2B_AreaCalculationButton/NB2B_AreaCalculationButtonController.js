({
	doInit : function(component, event, helper) {
		//var recordId = component.get('v.recordId');
        var action = component.get("c.checkShowButton");
        action.setParams({
            recordId : component.get("v.recordId"),
            url		 : null
        });            
        //action.setCallback(this, response => this.showButton(component, response));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var wrapper = response.getReturnValue();
            if (state === "SUCCESS" && wrapper != null && wrapper.isCorrect) {
                component.set('v.showButton', wrapper.showButton);
                component.set('v.product'	, wrapper.product);
                component.set('v.price'		, wrapper.price);                
                component.set('v.showUMV'	, true);
                component.set('v.webStoreId', wrapper.webStoreId);
                component.set('v.unitProductPrice', wrapper.productUnit);
                component.set('v.unitPrice', wrapper.priceUnit);


                if(wrapper.language != null){
                    component.set('v.userLanguage', wrapper.language.replace("_", "-"));
                }else{
                    component.set('v.userLanguage', 'en-US');
                }
                if(wrapper.product.UmbMt2__c == null || wrapper.product.UmbMt2__c == 0){
                    component.set('v.showButtonCmp'	, false);
                }
            }else{
                component.set('v.showButton', false);
            } 
        });
        $A.enqueueAction(action);     
	},
    showButton : function(component, response) { 
        var state = response.getState();
        var wrapper = response.getReturnValue();
        if (state === "SUCCESS") {
            component.set('v.showButton', wrapper.showButton);
        }else{
            component.set('v.showButton', false);
        } 
    },
    openModalBox : function(component, response) { 
        component.set('v.showComponent', true);
    },
    closeModal:function(component,event,helper){    
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open'); 
    },
    openmodal: function(component,event,helper) {
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open'); 
    },
    upBoxes : function(component, event, helper) {
		var quantity 	= component.get('v.quantity');
        var price 		= component.get('v.price');
        quantity = quantity + 1;
        component.set('v.quantity', quantity);
        helper.calculateTotals(component, event, helper);
        //component.set('v.priceTotal', (quantity * price.UnitPrice).toFixed(2));
	},
    onValueChange : function(component, event, helper) {

        helper.calculateTotals(component, event, helper);
        //component.set('v.priceTotal', (quantity * price.UnitPrice).toFixed(2));
	},
    downBoxes : function(component, event, helper) {
		var quantity 	= component.get('v.quantity');
        var price 		= component.get('v.price');
        if(quantity > 0){
        	quantity = quantity - 1;    
        }
        component.set('v.quantity', quantity);
        helper.calculateTotals(component, event, helper);
        //component.set('v.priceTotal', (quantity * price.UnitPrice).toFixed(2));
	},

    createCartItem : function(component, event, helper) {
        var action = component.get('c.sendToCart');
        action.setParams({
            recordId : component.get('v.recordId'),
            webStoreId : component.get('v.webStoreId'),
            quantity  :  component.get('v.quantity'),
            priceBookId : component.get('v.price').Id,
            salesOrg : window.sessionStorage.getItem('salesOrgCode'),
            amount : component.get('v.priceTotal')
        });            
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.showComponent', false);
                $A.get('e.force:refreshView').fire();
                //location.reload();
        	}else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "There was an error in the insertion"
                });
    			toastEvent.fire();
            } 
        });
        $A.enqueueAction(action);     
	}    
})