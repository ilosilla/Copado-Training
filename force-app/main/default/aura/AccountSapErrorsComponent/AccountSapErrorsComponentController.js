({
	doInit : function(component, event, helper) {
		console.log("update 2");
        
	},
    
    handleRefresh : function(component, event, helper) {
		
        helper.getAccountErrors(component);
        
	},
    
    handleRetry : function(component, event, helper) {
		
        let salesRelId = event.getSource().get("v.name");
        
        helper.retrySendToSAP(component, helper, salesRelId);
        
	},
    
    recordUpdated : function (component, event, helper){
        
        console.log("recordUpdated");
        
        var changeType = event.getParams().changeType;
        
        if (changeType === "ERROR") { 
            
            
            
        } else if (changeType === "LOADED") {
            console.log("record loaded");
            
            helper.getAccountErrors(component);
            
            
        } else if (changeType === "REMOVED") { 
            
            
            
        } else if (changeType === "CHANGED") {
            
            console.log("record updated");
            var changedFields = event.getParams().changedFields;
            console.log("changed fields: " + JSON.stringify(changedFields));
            
            var recordData = component.find("recordData");
            
            if(changedFields.hasOwnProperty('SAP_Id__c')){
                if(changedFields.SAP_Id__c.oldValue != changedFields.SAP_Id__c.value){
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "mode": "sticky",
                        "type": "success",
                        "message": $A.get("$Label.c.Success_during_SAP_Synchronization")
                    });
                    toastEvent.fire();
                    
                    recordData.reloadRecord();
                    $A.get('e.force:refreshView').fire();
                    
                }
            }
           	
            if(changedFields.hasOwnProperty('Sales_Rels_with_errors__c')){
                if(changedFields.Sales_Rels_with_errors__c.oldValue != changedFields.Sales_Rels_with_errors__c.value){
                    if(changedFields.Sales_Rels_with_errors__c.value > 0){
                        
                        recordData.reloadRecord();
                        
                    } else {
                        $A.get('e.force:refreshView').fire();
                    }
                }
            }
            
            
        }
        
    },
    
    salesRelUpdated : function (component, event, helper){
        
        console.log("recordUpdated");
        
        var changeType = event.getParams().changeType;
        
        if (changeType === "ERROR") { 
            
        } else if (changeType === "LOADED") {
            console.log("record loaded");
            
        } else if (changeType === "REMOVED") { 
            
        } else if (changeType === "CHANGED") {
            
            console.log("record updated");
            var changedFields = event.getParams().changedFields;
            console.log("changed fields: " + JSON.stringify(changedFields));
            var recordData = component.find("recordData");
            
            if(changedFields.hasOwnProperty('Sap_Status__c')){
                if(changedFields.Sap_Status__c.oldValue != changedFields.Sap_Status__c.value){
                    recordData.reloadRecord();
                }
            }
            
        }
        
    }
})