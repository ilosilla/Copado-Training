({
    /**
     * Reads the additional info of the related opp
     */
    readInfo : function(component) {
        var recordId = component.get("v.recordId");
        var projectId = component.get("v.customProjectId");
        component.set("v.customProjectId", null);
        var action = component.get("c.readOpportunityInfo");
        action.setParams({
            opportunityId : recordId,
            customProjectId : projectId
        });            
        action.setCallback(this, response => this.readInfoCallback(component, response));
        $A.enqueueAction(action);            
    }, // readInfo

    /*
     * Process response from readInfo
     */
    readInfoCallback : function(component, response) {          
        var state = response.getState();
        var dto = response.getReturnValue();                                
        var hasError = false;
        if(state === "SUCCESS") {  
            component.set("v.oppTypes", dto.options);
            if (dto.isCustomProject) {
                this.setCustomProjectMode(component, dto.customProjectId);
            } else if (dto.isKitchen) {
                this.setKitchenMode(component, dto.kitchenId);
            } else if (dto.isFacade) {
                this.setFacadeMode(component, dto.facadeId);

            } else {
                component.set("v.infoType", "NONE");
            }
        } else if (state === "ERROR") {
            this.handleErrors(component, response.getError());
        }
        component.set("v.showSpinner", false);
    }, // displayInfo

    /**
     * Deletes a custom project
     */
    deleteCustomProject : function (component) {
        component.set("v.showSpinner", true);
        var projectId = component.get("v.customProjectId");            
        var action = component.get("c.deleteCustomProject");
        action.setParams({
            customProjectId : projectId
        });            
        action.setCallback(this, response => this.deleteCustomProjectCallback(component, response));
        $A.enqueueAction(action);            

    }, // deleteCustomProject

    deleteCustomProjectCallback : function(component, response) {          
        var state = response.getState();
        var dto = response.getReturnValue();                                
        var hasError = false;
        if(state === "SUCCESS") {  
            component.set("v.infoType", "NONE");
            component.set("v.customProjectId", null);            
        } else if (state === "ERROR") {
            this.handleErrors(component, response.getError());
        }
        component.set("v.showSpinner", false);
    }, // deleteCustomProjectCallback

    /**
     * Deletes a kitchen
     */
     deleteKitchen : function (component) {
        component.set("v.showSpinner", true);
        var kitchenId = component.get("v.kitchenId");            
        var action = component.get("c.deleteKitchen");
        action.setParams({
            kitchenId : kitchenId
        });            
        action.setCallback(this, response => this.deleteKitchenCallback(component, response));
        $A.enqueueAction(action);            
    }, // deleteKitchen

    deleteKitchenCallback : function(component, response) {          
        var state = response.getState();
        var dto = response.getReturnValue();                                
        var hasError = false;
        if(state === "SUCCESS") {  
            component.set("v.infoType", "NONE");
            component.set("v.kitchenId", null);            
        } else if (state === "ERROR") {
            this.handleErrors(component, response.getError());
        }
        component.set("v.showSpinner", false);
    }, // deleteKitchenCallback

    /**
     * Deletes a Facade
     */
     deleteFacade : function (component) {
        component.set("v.showSpinner", true);
        var facadeId = component.get("v.facadeId");            
        var action = component.get("c.deleteFacade");
        action.setParams({
            facadeId : facadeId
        });            
        action.setCallback(this, response => this.deleteFacadeCallback(component, response));
        $A.enqueueAction(action);            
    }, // deleteFacade

    deleteFacadeCallback : function(component, response) {          
        var state = response.getState();
        var dto = response.getReturnValue();                                
        var hasError = false;
        if(state === "SUCCESS") {  
            component.set("v.infoType", "NONE");
            component.set("v.kitchenId", null);            
        } else if (state === "ERROR") {
            this.handleErrors(component, response.getError());
        }
        component.set("v.showSpinner", false);
    }, // deleteFacadeCallback

    setCustomProjectMode : function(component, projectId) {
        component.set("v.customProjectId", projectId);            
        component.set("v.infoType", "CUSTOMP");
        component.set("v.selectedType", "CUSTOMP");
        component.set("v.deleteMessage", $A.get("$Label.c.opp_customProjectDeleteW"));
    },

    setKitchenMode : function(component, id) {
        component.set("v.kitchenId", id);            
        component.set("v.infoType", "KITCHEN");
        component.set("v.selectedType", "KITCHEN");
        component.set("v.deleteMessage", $A.get("$Label.c.opp_customKitchenDeleteW"));
    },

    setFacadeMode : function(component, id) {
        component.set("v.facadeId", id);            
        component.set("v.infoType", "FACADE");
        component.set("v.selectedType", "FACADE");
        component.set("v.deleteMessage", $A.get("$Label.c.opp_facadeDeleteW"));
    },

    /*
     * server-side errors
     */
    handleErrors : function(component, errors) {
        var errorList = [];
        if (errors && Array.isArray(errors) && errors.length > 0) {
            for (var i=0; i<errors.length;i++) {
                errorList.push(errors[i].message);
            }
            component.set("v.errorList", errorList);
        }
    } // handleErrors    
        
})