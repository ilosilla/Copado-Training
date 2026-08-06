({
    CloseModal : function(component, event, helper) {
        console.log("close Modal");
        $A.get("e.force:closeQuickAction").fire();
    },

    refreshView : function(component, event, helper) {
        console.log("refreshView custom event");
        $A.get('e.force:refreshView').fire();
    },

    SaveModal : function(component, event, helper) {
        console.log("Save Aura");
        component.find('stockComponent').save();
        //$A.enqueueAction(component.get('c.CloseModal'));
        /*window.setTimeout(
            $A.getCallback(function() {
                let errors = component.find('stockComponent').validateErrors();
                console.log('5 secs ' + errors);
                if(errors != true){
                    helper.CloseModal();
                }
            }), 5000
        );*/
    },
    doInit : function(component, event, helper) {
		//var recordId = component.get('v.recordId');
        var action = component.get("c.checkOrder");
        action.setParams({
            orderId : component.get("v.recordId")
        });            
        //action.setCallback(this, response => this.showButton(component, response));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var wrapper = response.getReturnValue();
            if (state === "SUCCESS") {
                component.set('v.showMessage', wrapper);
                component.set('v.showComponent', true);
            } 
        });
        $A.enqueueAction(action);     
	},
    closeModal : function(component, event, helper) {
        helper.CloseModal();
	}
    

    /*SaveModal2 : function(component, event, helper) {
        component.find('stockComponent').save()
        .then(() =>{
            let errors = component.find('stockComponent').validateErrors();
            console.log('5 secs ' + errors);
            if(errors != true){
                helper.CloseModal();
            }
        })
        .catch((error) =>{
            console.log('checkStockWS ERROR' + JSON.stringify(error));
            this.showToast('ERROR', error, 'error', 'default');
        })
    }*/
})