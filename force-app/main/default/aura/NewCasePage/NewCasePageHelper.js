({
    buildPage : function(component)  {
        //component.set("v.submitting", true);
        //component.set("v.addressFields", address);
        var action = component.get("c.getCaseRecordTypes");
        action.setCallback(this, response => this.buildPageCallback(component, response));
        $A.enqueueAction(action);            
    },    

    buildPageCallback : function(component, response) {
        var state = response.getState();
        if (state === "SUCCESS") {              
            var result =  response.getReturnValue();
            var defaultType = '';
            var options = [];
            if (result) {
                this.setTabLabel(component,  $A.get("$Label.c.case_new_case_title"));                
                for (var i = 0; i<result.recordTypes.length; i++) {
                    var option = new Object();
                    option.value = result.recordTypes[i].id;
                    option.label = result.recordTypes[i].name;
                    if (result.recordTypes[i].description) {
                        option.label += ': ' + result.recordTypes[i].description;
                    }
                    if (result.recordTypes[i].isDefault) {
                        defaultType = result.recordTypes[i].id;
                    }
                    options.push(option);
                }
            }
            component.set("v.recordTypes", options);
            component.set("v.sapInvoiceId", result.sapInvoiceRecordTypeId);
            component.set("v.selectedRecordType", defaultType);
        } else {
            console.log('-----> [PORSA] Error reading Case Record Types');
            console.log('-----> [PORSA] State is ' + state);
            console.log('-----> [PORSA] Response is ' + JSON.stringify(response));
        }
    },

    setTabLabel : function(component, label) {
        var workspaceAPI = component.find('workspace');
        workspaceAPI.setTabLabel({
            label: label
        });

    },

    openCaseForm : function(component) {
        var sapInvoiceId = component.get('v.sapInvoiceId');
        var selectedId = component.get('v.selectedRecordType');
        if (selectedId == sapInvoiceId) {
            this.openCollectionCase(component);
        } else {
            this.openStandardCase(component, selectedId);
        }
    }, 

    /**
     * Opens a collection using a custom compoent
     */
    openCollectionCase : function(component) {
        var sapInvoiceId = component.get('v.sapInvoiceId');
        var pageReference = {
            'type': 'standard__component',
            'attributes': {
                'componentName': 'c__CaseCollectionForm'
            }
        };        
        var navService = component.find('navService');
        navService.navigate(pageReference, true);
    },

    /**
     * Opens a case using the standard layout defined for the record type
     */
    openStandardCase: function(component, recordTypeId) {
        var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                recordTypeId: recordTypeId
            }
        };
        var navService = component.find('navService');
        navService.navigate(pageReference, true);
    },

    /**
     * Closes the current tab
     */
    closeTab : function (component) {
        var workspaceAPI = component.find('workspace');
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });
        }).catch(function (error) {});
    }



})