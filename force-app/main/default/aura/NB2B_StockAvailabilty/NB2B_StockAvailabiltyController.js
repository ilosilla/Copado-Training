({
	doInit : function(component, event, helper) {
		//var recordId = component.get('v.recordId');
        var action = component.get("c.checkStock");
        action.setParams({
            recordId : component.get("v.recordId"),
            salesOrg : window.sessionStorage.getItem('salesOrgCode')
        });            
        //action.setCallback(this, response => this.showButton(component, response));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var wrapper = response.getReturnValue();
            if (state === "SUCCESS") {
                if(wrapper.isCorrect){
                    component.set('v.showStock', wrapper.isCorrect);
                    if(wrapper.responseStock != null && wrapper.responseStock[0].availstk != null && wrapper.responseStock[0].availstk > 0){
                        component.set('v.showGreen', true);
                    }else{
                         component.set('v.showYellow', true);
                    }
                }else{
                    component.set('v.showStock', wrapper.isCorrect);
                    //MIRAR DE INCLUIR ALGUNA LABEL COMO QUE EL SERVICIO HA FALLADO
                }
            }else{
                component.set('v.showStock', false);
            } 
            component.set('v.showSpinner',false);
            component.set('v.showLabel', true);
        });
        $A.enqueueAction(action);     
	}
})