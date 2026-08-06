({
    
    doInit : function(cmp, evt, hlpr){
        
        console.log("doInit");
        
        if(!$A.util.isEmpty(cmp.get("v.recordId"))){
            
            console.log('recordId not empty');
            hlpr.searchHelperById(cmp);
            
        }
        
    },
    
    onMouseLeave : function(cmp, evt, hlpr){
        
        cmp.set("v.searchResult", null);
        // Close resultList
        var searchBar = cmp.find("searchBar");
        $A.util.addClass(searchBar, 'slds-is-close');
        $A.util.removeClass(searchBar, 'slds-is-open');
        
    },
    
    onFocus : function(cmp, evt, hlpr){
        
        $A.util.addClass(cmp.find("spinner"), "slds-show");
        // Open resultList
        var searchBar = cmp.find("searchBar");
        $A.util.addClass(searchBar, 'slds-is-open');
        $A.util.removeClass(searchBar, 'slds-is-close');
        $A.util.removeClass(searchBar, 'slds-has-error');
        
        var element = document.querySelector("[data-index='" + cmp.get("v.objectApiName") + cmp.get("v.index") + "']");
        //var element = document.querySelector("[data-index*='" + cmp.get("v.objectApiName") + "']");
        //var element = document.querySelector("[data-index|='" + cmp.get("v.objectApiName") + "']"); doesn't work        
        var positionInfo = element.getBoundingClientRect();
        
        var width = positionInfo.width;
        console.log('width ' + width);
        cmp.set("v.width", positionInfo.width);
        
        var top = positionInfo.bottom;
        console.log('top ' + top);
        cmp.set("v.top", positionInfo.bottom);
        
        //console.log(positionInfo.top, positionInfo.right, positionInfo.bottom, positionInfo.left);
        
        /*var element2 = document.getElementById("uxxxlId");
        console.log(JSON.stringify(element2.getBoundingClientRect()));
        console.log('element2.style.width' +  element2.style.width);*/
        
        var formHelp = cmp.find("form-error-01");
        $A.util.addClass(formHelp, 'slds-hide');
        $A.util.removeClass(formHelp, 'slds-show');
        
        // Get Default 5 Records order by createdDate DESC  
        var inputKeyWord = '';
        hlpr.searchHelper(cmp, evt, inputKeyWord);        
        
    },
    
    keyPress : function(cmp, evt, hlpr) {
           
        var inputKeyWord = cmp.get("v.inputKeyWord");
  
        if(inputKeyWord.length > 0 ){
            
            // Open resultList
            var searchBar = cmp.find("searchBar");
            $A.util.addClass(searchBar, 'slds-is-open');
            $A.util.removeClass(searchBar, 'slds-is-close');
            
            hlpr.searchHelper(cmp,evt,inputKeyWord);
            
        }
        
        else{  
            
            cmp.set("v.searchResult", null);
            // Close resultList
            var searchBar = cmp.find("searchBar");
            $A.util.addClass(searchBar, 'slds-is-close');
            $A.util.removeClass(searchBar, 'slds-is-open');
            
        }
        
    },
    
    clear : function(cmp, evt, hlpr){

        var lookupPill = cmp.find("lookupPill");
        var lookupField = cmp.find("lookupField");
        
        $A.util.addClass(lookupPill, 'slds-hide');
        $A.util.removeClass(lookupPill, 'slds-show');
        
        $A.util.addClass(lookupField, 'slds-show');
        $A.util.removeClass(lookupField, 'slds-hide');
        
        cmp.set("v.inputKeyWord", null);
        cmp.set("v.searchResult", null);
        cmp.set("v.selectedRecord", {});
        
        /**/

		console.log('clear');
        
        var cmpEvent = cmp.getEvent("customSelectedRecordEvent");
        cmpEvent.setParams({
            "index" : cmp.get("v.index"),
            "selectedRecord" : cmp.get("v.selectedRecord"),
            "objectApiName" : cmp.get("v.objectApiName")
        });
        cmpEvent.fire();

    },
     
    handleComponentEvent : function(cmp, evt, hlpr) {
	 
        var selectedAccountGetFromEvent = evt.getParam("recordByEvent");
        cmp.set("v.selectedRecord" , selectedAccountGetFromEvent);
        
        var forclose = cmp.find("lookupPill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');
        
        var forclose = cmp.find("searchBar");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookupField = cmp.find("lookupField");
        $A.util.addClass(lookupField, 'slds-hide');
        $A.util.removeClass(lookupField, 'slds-show');

        /**/        
        var cmpEvent = cmp.getEvent("customSelectedRecordEvent");
        cmpEvent.setParams({
            "index" : cmp.get("v.index"),
            "selectedRecord" : cmp.get("v.selectedRecord"),
            "objectApiName" : cmp.get("v.objectApiName")
        });
        cmpEvent.fire();
        
    },
    
    fieldHasError : function(cmp, evt, hlpr){
        
        console.log('fieldHasError');       
        var params = evt.getParam('arguments');
        
        if(!Object.keys(cmp.get("v.selectedRecord")).length){
            
            hlpr.enableError(cmp, evt);
            return true;
            
        }
        
        else return false;
    
	}

})