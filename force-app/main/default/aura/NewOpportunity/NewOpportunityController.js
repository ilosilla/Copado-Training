({
    
    doInit : function(cmp){
        
        // Customer picks up the phone?
        var pickedUpRadioOptions = [
        	{'label': $A.get("$Label.c.Yes_the_customer_picks_up_the_phone"), 'value': 'Yes'},
        	{'label': $A.get("$Label.c.No_First_missed_call"), 'value': '1Missed'},
        	{'label': $A.get("$Label.c.No_Second_missed_call"), 'value': '2Missed'} 
        ];
            
        cmp.set("v.pickedUpRadioOptions", pickedUpRadioOptions);
        
        cmp.set("v.successFailureFinalScreen", false);
        cmp.set("v.firstScreen", true);
        cmp.set("v.lastScreen", false);
        //console.log("mail new: "+ cmp.get("v.newOpportunity").Account.PersonEmail);
    },
    
    changeScreen : function(cmp, evt, hlpr){
        
        var params = evt.getParam('arguments');
        
        if(params){
            
            var currentScreen = cmp.get("v.currentScreen");
            var numberOfScreens = cmp.get("v.numberOfScreens");
            var error;
            
            if(params.action == "Previous"){
                
                if(currentScreen > 1){
                    
                    cmp.set("v.currentScreen", currentScreen-1);
                    
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
                    
                    hlpr.validateFields(cmp, currentScreen);
                    error = cmp.get("v.error");
                    
                    if(!error){
                        
                        cmp.set("v.currentScreen", currentScreen+1);
                        
                        switch(currentScreen){
                                
                            case 1:
                                cmp.set("v.firstScreen", false);
                                break;
                                
                            case numberOfScreens-1:
                                cmp.set("v.lastScreen", true);
                                break;
                                
                        }
                    }
                }
            }
        }
    },
    
    reloadStage : function(cmp){
        
        cmp.set("v.currentScreen", 1);
        cmp.set("v.firstScreen", true);
        cmp.set("v.lastScreen", false);
        cmp.set("v.successFailureFinalScreen", false);
        cmp.set("v.fieldsToUpdate", {});
        cmp.set("v.error", false);
        
        cmp.set("v.finalMessage", undefined);
        cmp.set("v.pickedUpRadioValue", undefined);
        
    }
    
})