({
    loadAllData:  function(component) {
        component.set("v.showSpinner", true);
        var aux = this;
        component.set("v.isActive", true);
        this.getAllDataAjax(component, component.get("v.recordId")).then(function(result){
            var approverMode = component.get("v.approverMode");

            component.set("v.mode", result.isNew == false ? "EDIT" : "CREATE");
            component.set("v.opportunityData", result.opportunity);
            component.set("v.opportunityProducts", result.oppProducts);
            component.set("v.priceRequest", result.headerData);
            component.set("v.pricebook", result.pricebook);
            component.set("v.pricebookEntries", result.pricebookEntries);
            component.set("v.tariffPrices", result.tariffPrices);
            component.set("v.referencePrices", result.referencePrices)
            component.set("v.salesOrgs", result.salesOrgs);
            var workedItems = result.itemsData;
            if (approverMode == true) {
                workedItems = result.itemsData.filter(function(item) {
                    return item.FactoryStatus__c === 'PENDING';
                });
                workedItems.forEach(elem => {
                    if (elem.ApprovedPrice__c == null) {
                        elem.ApprovedPrice__c = elem.PriceNeeded__c;
                    }
                });
            }

            component.set("v.items", workedItems);   
            component.set("v.oppHasProducts", result.permissions.hasProducts);
            component.set("v.isStoreManager", result.permissions.isStoreManager);
            component.set("v.isFactoryManager", result.permissions.isFactoryManager);
            component.set("v.isStoreApprover", result.permissions.isStoreApprover);
            component.set("v.isFactoryApprover", result.permissions.isFactoryApprover);

            if (result.salesOrgs.length == 1) {
                component.set("v.priceRequest.SAPAccountingInfo__c", result.salesOrgs[0].id);
            }

            if (result.permissions.isFactoryManager && result.permissions.hasFactoryApprovers == true) {
                component.set("v.hasApprovers", true);
            }
            if (result.permissions.isStoreManager && result.permissions.hasStoreApprovers == true) {
                component.set("v.hasApprovers", true);
            }
            component.set("v.priceRequest.FactoryRequest__c", result.permissions.isFactoryManager);

             if (result.permissions.isEnabled == false) {
                 aux.showWarningMessage(component, $A.get('$Label.c.dict_acces_denied'), $A.get('$Label.c.dict_msg_not_available_yet'));
                 $A.enqueueAction(closeaction);
            } else if (result.permissions.hasProducts == false) {
                 aux.showWarningMessage(component, $A.get('$Label.c.dict_acces_denied'), $A.get('$Label.c.prequest_no_products'));
                 $A.enqueueAction(closeaction);
             } else if (result.permissions.isFactoryApprover == false && result.permissions.isFactoryManager == false && result.permissions.isStoreApprover == false && result.permissions.isStoreManager == false) {
                 aux.showWarningMessage(component, $A.get('$Label.c.dict_acces_denied'), $A.get('$Label.c.dict_msg_no_access'));
                 $A.enqueueAction(closeaction);
             } else {

                /* Sets metadata for each field on OppPriceRequestItem__c */
                var itemFields = [
                    {field: 'ProductCode__c', defaultValue: '', disabled: true, required: true, typeField: 'text', hide: false},
                    {field: 'ProductName__c', defaultValue: '', disabled: true, required: true, typeField: 'text', hide: false},
                    {field: 'Quantity__c', defaultValue: '', disabled: true, required: true, typeField: 'text', hide: false},
                    {field: 'ReferencePrice__c', defaultValue: '', disabled: true, required: true, typeField: 'number', hide: false},
                    {field: 'Price__c', defaultValue: '', disabled: true, required: true, typeField: 'number', hide: false},
                    {field: 'PriceNeeded__c', defaultValue: '', disabled: true, required: true, typeField: 'number', hide: false},
                    {field: 'CurrencyIsoCode', defaultValue: '', disabled: true, required: true, typeField: 'text', hide: true},
                    {field: 'UnitOfPrice__c', defaultValue: '', disabled: true, required: true, typeField: 'text', hide: false},
                    {field: 'Product__c', defaultValue: '', disabled: true, required: true, typeField: 'text', hide: true},
                    {field: 'PriceBook__c', defaultValue: '', disabled: true, required: false, typeField: 'text', hide: true},
                    {field: 'FactoryPrice__c', defaultValue: '', disabled: true, required: true, typeField: 'number', hide: false},
                    {field: 'FactoryPriceNeeded__c', defaultValue: '', disabled: false, required: true, typeField: 'number', hide: false},
                ];
                
                component.set("v.itemFields", itemFields);

                component.set("v.isActive", true);
                var title = $A.get('$Label.c.prequest_new');
                if (result.isNew == false) {
                    title = $A.get('$Label.c.prequest_edit');
                } else {
                    component.set("v.priceRequest.Opportunity__c", result.opportunity.Id);
                    component.set("v.priceRequest.CurrencyIsoCode", result.opportunity.CurrencyIsoCode == null ? '' : result.opportunity.CurrencyIsoCode);
                }
                if (approverMode == true) {
                    title = $A.get('$Label.c.prequest_review_prequest');
                }
                component.set("v.title", title);
                component.set("v.showSpinner", false);
             }
        }).catch(function (err) {
             console.log(err);
            aux.showErrorMessage(component, "Error!", err.message);
        });

    },
    /* Reloads all component with the last information*/
    reload : function(component) {
        component.set("v.showSpinner", true);
        component.set("v.selectedCount", 0);
        component.set("v.selectedToApprove", 0);
        component.set("v.selectedToReject", 0);
        this.loadAllData(component);
    },
    /* Empty the Panel Form */
    reloadItemForm : function(component) {
        var fields = component.get("v.itemFields");
        fields.forEach(function(elem) {
            component.set('v.itemPanel.' + elem.field,elem.defaultValue);
            elem.itemValue = elem.defaultValue;
        });
        component.set('v.itemPanel.OpportunityProduct__c', '');
        component.set("v.itemFields", fields);
        component.set("v.titlePanel", $A.get('$Label.c.prequest_new_item'));
    },
    /* It closes the component, either on a modal, or on an action modal */
    closeComponent : function(component) {
        var cmpEvent = component.getEvent("closeComponent");
        cmpEvent.fire();
        $A.get("e.force:closeQuickAction").fire();
    },
    /************************* AJAX CALLS ********************************/
    submitDeleteItemsAjax : function(component, items) {
        var action = component.get("c.deleteItems");
        action.setParams({
            items: items
        });
        return this.returnPromiseAjax(action);
    },
    submitDeletePriceRequestAjax : function(component, priceId) {
        var action = component.get("c.deletePriceRequest");
        action.setParams({
            priceId: priceId
        });
        return this.returnPromiseAjax(action);
    },
    submitNewPriceRequestAjax : function(component, priceRequest) {
        var action = component.get("c.createPriceRequest");
        action.setParams({
            priceRequest: priceRequest
        });
        return this.returnPromiseAjax(action);
    },
    submitUpdatePriceRequestAjax : function(component, priceRequest) {
        var action = component.get("c.updatePriceRequest");
        action.setParams({
            priceRequest: priceRequest
        });
        return this.returnPromiseAjax(action);
    },
    submitItemsForApprovalAjax : function(component, items) {
        console.log(component.get("v.isFactoryManager"))
        var action = component.get("c.itemsForFactoryApproval");

        action.setParams({
            items: items
        });
        return this.returnPromiseAjax(action);
    },
    submitApprovedAjax : function(component, approved) {
        var action = component.get("c.itemsFactoryApproved");
        action.setParams({
            approvedItems: approved
        });
        return this.returnPromiseAjax(action);
    },
    submitDeclinedAjax : function(component, rejected) {
        var action = component.get("c.itemsRejected");
        action.setParams({
            declinedItems: rejected
        });
        return this.returnPromiseAjax(action);
    },
    submitItemsAjax : function(component, item) {
        var action = component.get("c.upsertItem");
        action.setParams({
            item: item
        });
        return this.returnPromiseAjax(action);
    },
    updateOppProductPriceAjax : function(component, opportunityId, productLineId) {
        var action = component.get("c.updateOppProductPrice");
        action.setParams({
            oppId: opportunityId,
            oppProductLineId: productLineId
        });
        return this.returnPromiseAjax(action);
    },
    updateOppProductFactoryPriceAjax : function(component, opportunityId, productLineId) {
        var action = component.get("c.OppProductFactoryPrice");
        action.setParams({
            oppId: opportunityId,
            oppProductLineId: productLineId
        });
        return this.returnPromiseAjax(action);
    },
    getAllDataAjax : function(component, opportunityId) {
        var action = component.get("c.getAllData");
        action.setParams({
            opportunityId: opportunityId
        });
        return this.returnPromiseAjax(action);
    },
    /********* Global methods *************/
    showErrorMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            title: title,
            message: body,
            type: "error"
        });
        toastEvent.fire();
    },
    showWarningMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "warning"
        });
        toastEvent.fire();
    },
    showSuccessMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "success"
        });
        toastEvent.fire();
    },
    returnPromiseAjax : function(action) {
        return new Promise(function (resolve, reject) {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS"){
                    resolve(response.getReturnValue());
                } else if(state === "ERROR") {
                    var errors = action.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            // System Error
                            reject(errors[0]);
                        } else if (errors[0] && errors[0].pageErrors) {
                            // DML Error
                            // （This sample code is corner-cutting. It does not consider the errors in multiple records and fields.）
                            reject(errors[0].pageErrors[0]);
                        }
                    }
                }
            });         
            $A.enqueueAction(action);
        });
    }
})