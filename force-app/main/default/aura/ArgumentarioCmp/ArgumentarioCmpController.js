({
    
    doInit : function(cmp, evt, hlpr){
        
        //hlpr.getOpportunityDetails(cmp, recordId);
        
        // stageMap
        var stageMap = {
            ['New'] : $A.get("$Label.c.New_Opportunity"),
            ['Qualification'] : $A.get("$Label.c.Qualification"),
            ['Pending'] : $A.get("$Label.c.Pending"),
            ['Closed Won'] : $A.get("$Label.c.Closed_Won"),
            ['Closed Lost'] : $A.get("$Label.c.Closed_Lost")
        };
        
        cmp.set("v.stageMap", stageMap);
        
        var x = cmp.get("v.stageMap");
        console.log('stageMap' + JSON.stringify(x));
        console.log("opportunity update 52.");
        
    },
    
    previousStep : function(cmp){
        
        var stageMap = cmp.get("v.stageMap");
        var currentStage = cmp.get("v.currentStage");
        var childCmp;
        
        switch(currentStage) {
            case "New":
                childCmp = cmp.find("newId");
                childCmp.changeScreen("Previous");
                break;
			case "Qualification": 
                childCmp = cmp.find("qualificationId");
                childCmp.changeScreen("Previous");
                break;
            case "Pending":
                childCmp = cmp.find("pendingId");
                childCmp.changeScreen("Previous");
                break;
            case "Closed Won":
                childCmp = cmp.find("closedWonId");
                childCmp.changeScreen("Previous");
                break;
            case "Closed Lost":
                childCmp = cmp.find("closedLostId");
                childCmp.changeScreen("Previous");
                break;
            default:
                
        }
        
        //document.getElementById("scrollTo").scrollIntoView({block: "center"});
        
    },
    
    nextStep : function(cmp, evt, hlpr){
        
        var stageMap = cmp.get("v.stageMap");
        var currentStage = cmp.get("v.currentStage");
        var childCmp;
        
        switch(currentStage) {
            case "New":
                childCmp = cmp.find("newId");
                childCmp.changeScreen("Next");
                break;
			case "Qualification":
                childCmp = cmp.find("qualificationId");
                childCmp.changeScreen("Next");
                break;
            case "Pending":
                childCmp = cmp.find("pendingId");
                childCmp.changeScreen("Next");
                break;
            case "Closed Won":
                childCmp = cmp.find("closedWonId");
                childCmp.changeScreen("Next");
                break;
            case "Closed Lost":
                childCmp = cmp.find("closedLostId");
                childCmp.changeScreen("Next");
                break;
            default:
                
        }
        
        //document.getElementById("scrollTo").scrollIntoView({block: "center"});
        
    },
    
    finishStage : function(cmp, evt, hlpr){

        var currentStage = cmp.get("v.currentStage");
        var fieldsToUpdate = cmp.get("v.fieldsToUpdate");
        var stageMap = cmp.get("v.stageMap");
        
        if(currentStage === "Closed Won"){

            cmp.set("v.firstScreen", true);
        	cmp.set("v.lastScreen", true);    
        }
        
        hlpr.saveOpportunityDetails(cmp);
        cmp.set("v.currentStage", fieldsToUpdate.StageName);
        cmp.set("v.currentStageTranslated", stageMap[fieldsToUpdate.StageName] );
        
        //document.getElementById("scrollTo").scrollIntoView({block: "center"});
        
    },
    
    reloadStage : function(cmp,evt,hlpr){
        
        var stageMap = cmp.get("v.stageMap");
        var currentStage = cmp.get("v.currentStage");
        var childCmpId = currentStage.replace(/\s/g, '');
        
        childCmpId = childCmpId.charAt(0).toLowerCase() + childCmpId.slice(1) + 'Id';
        
        hlpr.saveOpportunityDetails(cmp);
        
        var childCmp = cmp.find(childCmpId);
        childCmp.reloadStage();
        
        //document.getElementById("scrollTo").scrollIntoView({block: "center"});
        
    },
    
    handleRecordUpdate : function(cmp, evt, hlpr){
        
        var changeType = evt.getParams().changeType;
        
        if (changeType === "ERROR") {
            alert("Error getting the opportunity details. " + cmp.get("v.recordError"));
            
        }else{
            var cmp1 = cmp.find("forceRecordCmp");
            var targetFields = cmp1.get("v.targetFields");
            var stageMap = cmp.get("v.stageMap");
            
            console.log("targetFields: " + JSON.stringify(targetFields));
            
            cmp.set("v.currentStage", targetFields.StageName);
            cmp.set("v.currentStageTranslated", stageMap[targetFields.StageName] );
            
            
            if(changeType === "LOADED"){    
            }else if(changeType === "CHANGED"){
                var changedFields = evt.getParams().changedFields;
                console.log("changed fields: " + JSON.stringify(changedFields));
                
                if(cmp.get("v.currentStage") === "Closed Won" && changedFields.hasOwnProperty("Close_Mode__c")){
                    if(changedFields.Close_Mode__c.oldValue !== changedFields.Close_Mode__c.value){
                		
                        cmp1.reloadRecord();
                        var childCmp = cmp.find("closedWonId");
                        childCmp.reloadStage();
                		
                    }
                }
            }
        }
    },
    
})