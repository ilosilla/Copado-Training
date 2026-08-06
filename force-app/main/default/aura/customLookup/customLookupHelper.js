({
    
    searchHelper : function(cmp, evt, inputKeyWord){
        
        var action = cmp.get("c.fetchLookUpValues");
        action.setParams({
            'searchKeyWord': inputKeyWord,
            'objectApiName' : cmp.get("v.objectApiName")
        });
   
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            console.log(JSON.stringify(serverResponse));
            
            if (state === "SUCCESS") {
                
                $A.util.removeClass(cmp.find("spinner"), "slds-show");
                
                if(serverResponse.length == 0){cmp.set("v.Message", 'No Result Found...');}                
                else{cmp.set("v.Message", '');}
                
                cmp.set("v.searchResult", serverResponse);
                
            }
            
        });

        $A.enqueueAction(action);
        
    },
    
    searchHelperById : function(cmp){
        
        var action = cmp.get("c.fetchLookUpValuesById");
        action.setParams({
            'recordId': cmp.get("v.recordId"),
            'objectApiName' : cmp.get("v.objectApiName")
        });
   
        action.setCallback(this, function(response){
            
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            console.log(JSON.stringify(serverResponse));
            
            if (state === "SUCCESS") {
                
                cmp.set("v.selectedRecord", serverResponse[0]);
                
                var forclose = cmp.find("lookupPill");
                $A.util.addClass(forclose, 'slds-show');
                $A.util.removeClass(forclose, 'slds-hide');
                
                var forclose = cmp.find("searchBar");
                $A.util.addClass(forclose, 'slds-is-close');
                $A.util.removeClass(forclose, 'slds-is-open');
                
                var lookupField = cmp.find("lookupField");
                $A.util.addClass(lookupField, 'slds-hide');
                $A.util.removeClass(lookupField, 'slds-show');
                
            }
            
        });

        $A.enqueueAction(action);
        
    },
    
    enableError : function(cmp, evt){
        
        var forError = cmp.find("searchBar");
        $A.util.addClass(forError, 'slds-has-error');
        var formHelp = cmp.find("form-error-01");
        $A.util.addClass(formHelp, 'slds-show');
        $A.util.removeClass(formHelp, 'slds-hide');
        
        
    }
    
})