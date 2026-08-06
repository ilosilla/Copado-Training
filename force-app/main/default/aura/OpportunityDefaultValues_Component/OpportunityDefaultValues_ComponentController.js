({
    doInit : function(cmp, evt, hlpr) {
        
        //console.log("doInitX");
        
        //console.log("recordID: " + cmp.get("v.recordId"));
        /*console.log("sObjectName: " + cmp.get("v.sObjectName"));
        console.log("pageReference" + JSON.stringify(cmp.get("v.pageReference")));*/
        
        if($A.get("$Browser.formFactor") == 'DESKTOP'){
            
            if(cmp.get("v.pageReference").state.hasOwnProperty('ws')){
                
                var pageReference = cmp.get("v.pageReference");
                //console.log('pageReference' + JSON.stringify(pageReference));
                var ws = pageReference.state.ws;
                var accountId = ws.substring(ws.indexOf('001'), ws.indexOf('/view'));
                var recordTypeId = pageReference.state.recordTypeId;
                
                console.log("recordTypeId: " + recordTypeId);
                
                cmp.set("v.recordId", accountId);
                cmp.find("recordEditor").reloadRecord();
                
                if(recordTypeId == undefined){
                    hlpr.getRecordTypeDefault(cmp);
                } else {
                    
                    cmp.set("v.recordTypeId", recordTypeId);
                    cmp.find("recordTypeEditor").reloadRecord();
                }
                
                
                
            } else {
                
                hlpr.createRecordWithDefault(cmp);
                
            }
            
        }
        
        else{
            
            //sforce.one.createRecord();
            
        }
        
    },
    
    recordUpdated : function (cmp, evt, hlpr){
        
        console.log("recordUpdated");
        console.log("params: " + JSON.stringify(evt.getParams()));
        
        var changeType = evt.getParams().changeType;
        
        if (changeType === "ERROR") { 
            
            /* handle error; do this first! */ 
            hlpr.createRecordWithDefault(cmp);
            
        } else if (changeType === "LOADED") {
            
            console.log("record loaded");
            /*console.log("recordId " + cmp.get("v.recordId"));
            console.log("record " + JSON.stringify(cmp.get("v.record")));
            console.log("simpleRecord " + JSON.stringify(cmp.get("v.simpleRecord")));
            console.log("recordTypeId " + cmp.get("v.recordTypeId"));*/
            
            cmp.set("v.recordLoaded", true);
            
            if(cmp.get("v.recordTypeLoaded")){
                hlpr.createRecordWithDefault(cmp);
            }
            
        } else if (changeType === "REMOVED") { 
            
            /* handle record removal */ 
            
        } else if (changeType === "CHANGED") {
            
        }
        
    },
    
    recordTypeUpdated : function (cmp, evt, hlpr){
        
        console.log("recordTypeUpdated");
        //console.log("params: " + JSON.stringify(evt.getParams()));
        
        var changeType = evt.getParams().changeType;
        
        if (changeType === "ERROR") { 
            
            /* handle error; do this first! */ 
            hlpr.createRecordWithDefault(cmp);
            
        } else if (changeType === "LOADED") {
            
            console.log("recordType loaded");
            
            cmp.set("v.recordTypeLoaded", true);
            
            if(cmp.get("v.recordLoaded")){
                hlpr.createRecordWithDefault(cmp);
            }
            
        } else if (changeType === "REMOVED") { 
            
            /* handle record removal */ 
            
        } else if (changeType === "CHANGED") {
            
            
        }
        
    }
    
})