({
    getSAPDocuments : function(component) {
        var errorList = [];
        this.showSpinner(component);
        component.set("v.errorList", errorList);
        component.set("v.documents", []);
        this.setTabTitle(component, 'Loading');
        var docType = component.get("v.docType");
        var accountId = component.get("v.accountId");
        var salesOrg = component.get("v.salesOrg");   
        var opportunityId = component.get("v.opportunityId");        
        if (accountId != null) {
            var action = component.get("c.getSAPDocuments");     
            action.setParams({
                docType: docType,
                accountId : accountId,
                salesOrg: salesOrg
            });
        } else {
            action = component.get("c.getOPPDocuments");     
            action.setParams({
                docType: docType,
                opportunityId : opportunityId,
                salesOrg: salesOrg
            });
        }
        action.setCallback(this, function(response) {
            var strStatus = $A.get('$Label.c.dict_updatedAt');
            strStatus = strStatus.replace('&1', new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
            component.set("v.timeUpdated", strStatus);
            var state = response.getState();
            var serverResponse = response.getReturnValue();   
            this.setTabTitle(component, component.get('v.titleType'));
            if(state === "SUCCESS"){   
                var dto = serverResponse;
                component.set("v.documents", dto.items);
                component.set("v.ndocuments", dto.items.length);
                component.set("v.breadcrumb1", dto.breadcrumb1);
                component.set("v.breadcrumb2", dto.breadcrumb2);
                component.set("v.showEmptyList", (dto.items.length == 0));
                component.set("v.showTooltip", (dto.items.length > 0));
                this.setOrderField(component, 'hDate', true);
                this.showPermissionsWarning(component, dto.permissionErrors);
            } else if(state === "INCOMPLETE"){                
            } else if(state === "ERROR"){                    
                this.handleErrors(component, response.getError());
            }            
            this.hideSpinner(component, false);
        }); 
        $A.enqueueAction(action);
    },

    showPermissionsWarning : function(component, orgs) {
        if (orgs.length > 0) {
            var toastEvent = $A.get("e.force:showToast");
            var message = $A.get("$Label.c.saps_orgsPermission");
            message = message.replace('{0}', orgs.join(' ,'));
            toastEvent.setParams({
                "type": "warning",
                "title": "Warning!",
                "mode": "sticky", 
                "message": message
            });
            toastEvent.fire();
        }
    }, // showPermissionsWarning

    handleErrors : function(component, errors) {
        var errorList = [];
        if (errors && Array.isArray(errors) && errors.length > 0) {
            for (var i=0; i<errors.length;i++) {
                errorList.push(errors[i].message);
            }
            component.set("v.errorList", errorList);
            component.set("v.showErrors", true);
        }
    }, // handleErrors

    sortList : function (component, id) {
        var items = component.get("v.documents");
        if (!items) {
            return;
        }
        var ascending = true;
        var currentOrder = component.get("v.orderField");
        if(currentOrder && currentOrder.toLowerCase() == id.toLowerCase()) {
            ascending = component.get("v.orderAscending");
            ascending = !ascending;
        }
        var key = '';
        switch (id.toLowerCase()) {
            case 'hamount':
                key = 'Dtotal__c';
                break;
            case 'hdate':
                key = 'Orderdate__c';
                break;
            case 'hnumber':
                key = 'Ordernum__c';
                break;
            case 'hreference':
                key = 'Refer__c';
                break;   
            default:
                return;
                break; 
        } // switch
        this.sortByKey(items, key, ascending);            
        this.setOrderField(component, id, ascending);
        component.set("v.documents", items);                            
    },

    sortByKey : function (array, key, ascending) {
        return array.sort(function(a, b) {
            var x = a[key]; var y = b[key];
            if (ascending) {
                return ((x < y) ? -1 : ((x > y) ? 1 : 0));
            } else {
                return ((x > y) ? -1 : ((x < y) ? 1 : 0));
            }
        });
    },    

    setOrderField : function(component, id, ascending) {
        var iconId = '';
        var currentField = component.get ("v.orderField");
        component.set("v.orderField", id);
        component.set("v.orderAscending", ascending);
        if (currentField) {
            iconId = currentField + '-icon';
            $A.util.addClass(component.find(iconId), 'slds-hide');
        }
        iconId = id + '-icon';
        var iconName = 'utility:arrowup';
        if (!ascending) {
            iconName = 'utility:arrowdown';
        }
        component.find(iconId).set("v.iconName", iconName);
        $A.util.removeClass(component.find(iconId), 'slds-hide');
    },

    setTabTitle : function(component, strTitle) {
        var workspaceAPI = component.find("sapdocsWS");
        var tabId = component.get("v.tabId");
        workspaceAPI.setTabLabel({
            label: strTitle
        });
    },

    getEnclosingTabId : function(component) {
        var workspaceAPI = component.find("sapdocsWS");
        workspaceAPI.getEnclosingTabId().then(function(tabId) {
            component.set("v.tabId", tabId);
       })
        .catch(function(error) {
        });
    },

    customiseForm : function(component, docType, salesOrg, accountId, variant) {        
        if (variant == 'OPP') {
            this.customiseOppForm(component, docType, salesOrg, accountId);
        } else {
            this.customiseAccForm(component, docType, salesOrg, accountId);
        }
    }, // customiseForm

    customiseAccForm : function(component, docType, salesOrg, accountId, variant) {        
        // Defaults        
        var iconType = 'standard:orders';
        var listTitle = $A.get('$Label.c.saps_row_openOrders');
        var titleType = $A.get('$Label.c.dict_orders');        
        var description = $A.get('$Label.c.dict_order');
        switch (docType.toUpperCase()) {
            case 'Q':
                iconType = 'standard:quotes';
                listTitle = $A.get('$Label.c.saps_row_openQuotes');
                titleType = $A.get('$Label.c.dict_quotes');        
                description = $A.get('$Label.c.dict_quote');                
                break;            
            case 'I': 
                iconType = 'standard:timesheet';
                listTitle = $A.get('$Label.c.saps_row_openInvoices');
                titleType = $A.get('$Label.c.dict_invoices');        
                description = $A.get('$Label.c.dict_invoice');
                break;            
        } // switch 
        component.set('v.docType', docType);
        component.set('v.accountId', accountId);
        component.set('v.salesOrg', salesOrg);
        component.set('v.iconType', iconType);
        component.set('v.titleType', titleType);
        component.set('v.listTitle', listTitle);
        component.set('v.description', description);
    }, // customiseAccForm

    customiseOppForm : function(component, docType, salesOrg, accountId, variant) {        
        // Defaults        
        var iconType = 'standard:orders';
        var listTitle = $A.get('$Label.c.saps_row_oppOrders');
        var titleType = $A.get('$Label.c.dict_orders');        
        var description = $A.get('$Label.c.dict_order');
        switch (docType.toUpperCase()) {
            case 'Q':
                iconType = 'standard:quotes';
                listTitle = $A.get('$Label.c.saps_row_oppQuotes');
                titleType = $A.get('$Label.c.dict_quotes');        
                description = $A.get('$Label.c.dict_quote');                
                break;            
            case 'I': 
                iconType = 'standard:timesheet';
                listTitle = $A.get('$Label.c.saps_row_oppInvoices');
                titleType = $A.get('$Label.c.dict_invoices');        
                description = $A.get('$Label.c.dict_invoice');
                break;            
        } // switch 
        component.set('v.docType', docType);
        component.set('v.accountId', accountId);
        component.set('v.salesOrg', salesOrg);
        component.set('v.iconType', iconType);
        component.set('v.titleType', titleType);
        component.set('v.listTitle', listTitle);
        component.set('v.description', description);
    }, // customiseAccForm,

    showSpinner : function(component) {
        component.set("v.showSpinner", true);
        component.set("v.showErrors", false);
        component.set("v.showTooltip", false);
        component.set("v.showDocument", false);
        component.set("v.showEmptylist", false);
    },

    hideSpinner : function(component) {
        component.set("v.showSpinner", false);
    }

    
})