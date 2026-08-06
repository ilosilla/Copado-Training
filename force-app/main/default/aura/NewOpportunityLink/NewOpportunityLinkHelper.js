({
	getButtons : function(component) {
        var action = component.get("c.getButtonsInfo");
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) { 
                console.log(response.getError()[0]);
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
    },
    
    getUserData : function(component) {       
         var action = component.get("c.getUserData");
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
    },
    
    getUrlTPlanner : function(component, langCode) {
        var action = component.get("c.getUrlTilePlanner");
        action.setParams({
            languageCode : langCode
        });
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  console.log('OK')
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {      
                  console.log('KO')
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
    },
    
    newMoodboard : function(component) {
        var action = component.get("c.createNewMoodboard");
        action.setParams({
            oppId : component.get("v.recordId")
        });
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
    },
    
    newCounterTop : function(component) {
        var action = component.get("c.createNewCounterTop");
        action.setParams({
            oppId : component.get("v.recordId")
        });
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) { 
              var state = response.getState();
              if(state === "SUCCESS"){
                  resolve(response.getReturnValue());
              } else if(state === "ERROR") {                    
                  reject(response.getError()[0]);
              }            
          	});
            $A.enqueueAction(action);
        });
    },
    
    openNewTilePlanner : function(component) {
        const currentDomain = window.location.hostname;
        const isProduction = currentDomain.includes('.my.salesforce.com');
        var linkUrl;
        var currentUser = component.get("v.currentUser");
        this.getUrlTPlanner(component, currentUser.LanguageLocaleKey).then(function(result) {
            linkUrl = result + '?oppId=' + component.get("v.recordId") + '&email=' + currentUser.Username;
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": linkUrl
            });
            urlEvent.fire();
        });
    },
    
    openNewMoodboard : function(component) {
        var aux = this;
        Promise.all([aux.newMoodboard(component)]).then(function(results) {
            var linkUrl = results[0];
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": linkUrl
            });
            urlEvent.fire();
        });
    },
    
    openNewCounterTop : function(component) {
        var aux = this;
        Promise.all([aux.newCounterTop(component)]).then(function(results) {
            console.log('CCCCC');
                        console.log(results);
            var linkUrl = results[0];
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": linkUrl
            });
            urlEvent.fire();
        });
    },
    
    showOptions : function(component) {
        component.set("v.showOptions", true);
    },
    
    closeComponent : function(component) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    showAlert : function(component) {
        var aux = this;
        this.LightningAlert.open({
            message: $A.get("$Label.c.dict_msg_no_access"),
            theme: 'warning',
            label: $A.get("$Label.c.dict_error")
        }).then(function() {
            aux.closeComponent(component);
        });
    }
})