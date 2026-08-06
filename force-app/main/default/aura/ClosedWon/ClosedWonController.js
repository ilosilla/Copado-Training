({
	doInit : function(component, event, helper) {
		var comboOptionsReasonForClosure = [
            {'label': $A.get("$Label.c.In_shop_date"), 'value': 'In shop date'}, 
            {'label': $A.get("$Label.c.E_commerce"), 'value': 'E-commerce'}
        ];
        
        component.set("v.comboOptionsReasonForClosure", comboOptionsReasonForClosure);
        
        var opportunity = component.get("v.opportunity");
        
        component.set("v.firstScreen", true);
        
        // Si la oportunidad ya tiene un modo de cierre entonces solo muestra el cartel final de oportunidad cerrada.
        if(opportunity.Close_Mode__c === 'In shop date' || opportunity.Close_Mode__c === 'E-commerce'){
        	
            component.set("v.currentScreen", 2);
            component.set("v.lastScreen", true);
            
        } else{
        	component.set("v.currentScreen", 1);
            component.set("v.lastScreen", false);
            
        }
        console.log("update 7");
	},
    
    changeScreen : function(cmp, evt, hlpr){
        
        var params = evt.getParam('arguments');
        
        if(params){
            
            var currentScreen = cmp.get("v.currentScreen");
            var numberOfScreens = cmp.get("v.numberOfScreens");
            var error;
            
            if(params.action == "Previous"){
                
                if(currentScreen > 1){
                    
                    cmp.set("v.currentScreen", currentScreen - 1);
                    
                    switch(currentScreen){
                            
                        case 2:
                            
                            cmp.set("v.firstScreen", true);
                            break;
                            
                        case numberOfScreens:
                            
                            cmp.set("v.lastScreen", false);
                            cmp.set("v.successFailureFinalScreen", false);
                            break;
                            
                    }
                }
            }
            
            else if(params.action == "Next"){
                
                if(currentScreen < numberOfScreens){
                    
                    hlpr.validateFields(cmp);
                    error = cmp.get("v.error");
                    
                    if(!error){
                        
                        cmp.set("v.currentScreen", currentScreen + 1);
                        
                        switch(currentScreen){
                                
                            case 1:
                                cmp.set("v.firstScreen", false);
                                cmp.set("v.lastScreen", true);
                                hlpr.completeStage(cmp);
                                break;
                                
                            case numberOfScreens - 1:
                                cmp.set("v.lastScreen", true);
                                break;
                                
                        }
                    }
                }
            }
        }
        
    },
    
    reloadStage : function(component){
        
        var opportunity = component.get("v.opportunity");
        component.set("v.firstScreen", true);
        
        if(opportunity.Close_Mode__c == 'In shop date' || opportunity.Close_Mode__c == 'E-commerce'){
        	
            component.set("v.currentScreen", 2);
            component.set("v.lastScreen", true);
        } else{
        	
            component.set("v.currentScreen", 1);
            component.set("v.lastScreen", false);
        }
        
        component.set("v.successFailureFinalScreen", false);
        component.set("v.fieldsToUpdate", {});
        component.set("v.comboValueReasonForClosure", undefined);
        
    }
    
})