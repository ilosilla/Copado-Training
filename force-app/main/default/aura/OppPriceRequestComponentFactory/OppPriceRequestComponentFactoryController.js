({
	init : function(component, event, helper) {
        component.set("v.showSpinner", true);
        component.set("v.isActive", false);
        //helper.loadData(component, true);
        helper.loadAllData(component);
        //component.set("v.showSpinner", false);
    },
    /* Reloads the component */
    reload : function(component, event, helper) {
        helper.loadAllData(component);
    },
    /* Collapses the Item form panel */
    collapsePanel : function(component, event, helper) {
        component.set("v.isExpanded", false);
        component.set("v.itemEditingIndex", '');
        helper.reloadItemForm(component);
    },
    /* It opens the Item form panel */
    openPanel : function(component, event, helper) {
        component.set("v.isExpanded", true);
        component.set("v.editingItem", false);
        helper.reloadItemForm(component);
    },
    /* Collapses the Header form panel */
    collapsePanelHeader : function(component, event, helper) {
        component.set("v.isExpandedHeader", false);
        component.set("v.itemEditingIndex", '');
        helper.reloadItemForm(component);
    },
    /* It opens the Header form panel */
    openPanelHeader : function(component, event, helper) {
        component.set("v.isExpandedHeader", true);
        // helper.reloadItemForm(component);
    },
    enableSaveButton : function(component, event, helper) {
        component.set('v.saveEnabled', true);
    },
    /* Adds an Item to the list of a Price Request's items.
     * If it's a new Price Request, adds the item to the item list of the new, and non existing, Price Request
     * If it's an existing Price Request, it adds the item saving it directly on database
     */
    saveItem : function(component, event, helper) {
        event.preventDefault();
        
       	var priceRequest = component.get("v.priceRequest");
        var allItems = component.get("v.items");
        var itemFields = component.get("v.itemFields");
        var approverMode = component.get("v.approverMode");
        var indexEditingItem = component.get("v.itemEditingIndex");
        var priceRequestItemFields = event.getParam('fields');
        var auxItem = null;
        var opportunityProducts = component.get("v.opportunityProducts");
        component.set("v.validItemForm", true);

        /* If an item has been selected to edit, we need to load the existing data of the item as a base */
        if (indexEditingItem > -1){
            auxItem = Object.assign({}, allItems[indexEditingItem]);
        } else {
            auxItem = {};
        }

        var formError = false;
        var formErrorText = '';
        if (!approverMode) {
            /* We put on AuxItem the values of the fields on the form*/
            var productItemSelected = component.find('OpportunityProduct__c').get("v.value");
            var productSelectedData = opportunityProducts.filter(elem => elem.Id == productItemSelected);
            auxItem['OpportunityProduct__c'] = productItemSelected;
            itemFields.forEach(function(elem) {
                /* When we edit a field on the form, is returned as a text, even if it's a number. It should be transformed so
                * Salesforce can store it properly. If not, on a Spanish locale, the decimals don't work*/
                if (elem.typeField == 'number' && priceRequestItemFields[elem.field] != null && priceRequestItemFields[elem.field] != '') {
                    auxItem[elem.field] = parseFloat(priceRequestItemFields[elem.field]);
                } else {
                    auxItem[elem.field] = priceRequestItemFields[elem.field];
                }
            });

            /* Check the values of the fields */
            var reg = new RegExp('^[0-9]+$');

            if (auxItem['PriceNeeded__c'] >= auxItem['Price__c'] || auxItem['PriceNeeded__c'] >= auxItem['Price__c']) {
                formErrorText += $A.get('$Label.c.prequest_price_needed_inferior') + ' ';
                formError = true;
            }

            if (auxItem['PriceNeeded__c'] < (auxItem['ReferencePrice__c']*0.30)) {
                formErrorText += $A.get('$Label.c.prequest_discount_limit') + ' ';
                formError = true;
            }
            const blockedMeasures = ["MT2", "M", "M2", "SQF"];
            if (blockedMeasures.includes(auxItem['UnitOfPrice__c']) && auxItem['Quantity__c'] <= 1) {
                formErrorText += $A.get('$Label.c.prequest_minimum_quantity') + ' ';
                formError = true;
            }

            if (formError == true){
                var errMessage = component.find('ItemMessage');
                helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), formErrorText);
            } else {
                /* It's an existing Price request Item, so we save the item on the database */
                if (auxItem.Id == null){
                    auxItem.PriceRequestHeader__c = priceRequest.Id;
                    auxItem.Status__c = 'NOTSENT';
                }
            }
        }

        if (formError == false){
            helper.submitItemsAjax(component, auxItem).then(function(result){
                component.set("v.items", allItems);
                component.set("v.itemEditingIndex", -1);
                helper.reloadItemForm(component);
                component.set("v.isExpanded", false);
                helper.reload(component);
            }).catch(function (err) {
                console.log(err);
                helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            });
        }
    },
    /* We put on the panel form the values of the item selected to edit */
    prepareEditForm : function(component, event, helper) {
        var itemFields = component.get("v.itemFields");
        var pricebook = component.get("v.pricebook");
        var listOfAllItems = component.get("v.items");
        var indexToEdit = event.getParam('itemIndex');
        var approverMode = component.get("v.approverMode");
        component.set("v.editingItem", true);
        if (indexToEdit !== null && indexToEdit != 'undefined' && listOfAllItems[indexToEdit] !== null && listOfAllItems[indexToEdit] != 'undefined') {
            component.set("v.itemEditingIndex", indexToEdit);
            helper.reloadItemForm(component);
            itemFields.forEach(function(elem) {
                component.set('v.itemPanel.' + elem.field, listOfAllItems[indexToEdit][elem.field]);
                component.set('v.itemFields[10].disabled', false);
                if (elem.field == 'FactoryPrice__c' && listOfAllItems[indexToEdit]['FactoryPrice__c'] == null) {
                    component.set('v.itemFields[10].disabled', false);
                }
                elem.itemValue = listOfAllItems[indexToEdit][elem.field];
            });

            component.set('v.itemPanel.OpportunityProduct__c', listOfAllItems[indexToEdit]['OpportunityProduct__c']);
        }
        component.set("v.itemFields", itemFields);
        component.set("v.titlePanel", $A.get('$Label.c.prequest_edit_item'));
        component.set("v.isExpanded", true);
        if (approverMode) {
            component.set('v.itemPanel.Notes__c', '');
        }
    },
    updateItemsCount : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var itemsCheck = 0;
        var itemstoApprove = 0;
        var itemstoReject = 0;
        
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (listOfAllItems[i].isChecked == true) {
                itemsCheck++;
            } else if (listOfAllItems[i].isCheckedReject == true) {
                itemstoReject++;
            } else if (listOfAllItems[i].isCheckedApprove == true) {
                itemstoApprove++;
            }
        }
        
        component.set("v.selectedCount", itemsCheck);
        component.set("v.selectedToApprove", itemstoApprove);
        component.set("v.selectedToReject", itemstoReject);
    },
    /* Shows the Confirmation pop-up */
    submitDeleteConfirmation : function(component, event, helper) {
        var itemsSelected = component.get("v.selectedCount");
        var textBodySubmit = $A.get('$Label.c.prequest_delete_confirm');
        textBodySubmit = textBodySubmit.replace('#NUMITEMS', itemsSelected);
        component.set("v.textConfirmSubmit", textBodySubmit);
        component.set('v.buttonActionSelected', 'DELETE');
        
        var modal = component.find('modalConfirmSubmit');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
    },
    /* Deletes an item of the list */
    submitDeleteItems : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var itemsToDelete = [];
        var needsAjax = false;
        
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (listOfAllItems[i].isChecked == true) {
                if (listOfAllItems[i].Id != null && listOfAllItems[i].Id != 'undefined') {
                    itemsToDelete.push(listOfAllItems[i]);
                }
            }
        }
        
        helper.submitDeleteItemsAjax(component, itemsToDelete).then(function(results){
            helper.reload(component);
        }).catch(function (err) {
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
    },
    /* Shows the Confirmation pop-up */
    submitForApprovalConfirmation : function(component, event, helper) {
        var itemsSelected = component.get("v.selectedCount");
        var textBodySubmit = $A.get('$Label.c.prequest_approval_confirm');
        textBodySubmit = textBodySubmit.replace('#NUMITEMS', itemsSelected);
        component.set("v.textConfirmSubmit", textBodySubmit);
        component.set('v.buttonActionSelected', 'APPROVAL');
        
        var modal = component.find('modalConfirmSubmit');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
    },
    /* Send the selected items for approval. The Status changes to PENDING */
    submitApproval : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var listOfAllItems = component.get("v.items");
        var itemsForApproval = [];

        listOfAllItems.forEach(function(elem, index, object) {
            if (elem.isChecked == true) {
                itemsForApproval.push(elem);
            }
        });
        
        helper.submitItemsForApprovalAjax(component, itemsForApproval).then(function(results){
            helper.reload(component);
        }).catch(function (err) {
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
        
        component.set("v.items", listOfAllItems);
    },
    /* Creates a New Price Request and the items related to it */
    submitNewPriceRequest : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var priceRequest = component.get("v.priceRequest");
        var opportunity = component.get("v.opportunityData");
        priceRequest.Opportunity__c = opportunity.Id;
        var errorText = '';
        var aux = $A.get('$Label.c.dict_required');
        aux = aux.replace('<b>', '').replace('</b>','');
        var hasError = false;
        
        /* Checks if the required Price Request fields are not empty */
        if (priceRequest.NeededBy__c == null || priceRequest.NeededBy__c == ''){
            errorText +=$A.get('$Label.c.prequest_needed_by');
            hasError = true;
        }
        if (priceRequest.CurrencyIsoCode == null || priceRequest.CurrencyIsoCode == '') {
            errorText += (hasError == true ? ', ' : '') + $A.get('$Label.c.dict_currency');
            hasError = true;
        }
        if (hasError == true) {
            component.set("v.showSpinner", false);
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), aux.replace('&1', errorText));
        } else {
         	helper.submitNewPriceRequestAjax(component, priceRequest).then(function(results){
                helper.loadAllData(component);
            }).catch(function (err) {
                component.set("v.showSpinner", false);
                helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            });   
        }
    },
    /* Updates an existing Price Request and the items related to it */
    submitUpdatePriceRequest : function(component, event, helper) {
        event.preventDefault();
        var priceRequest = component.get("v.priceRequest");
        var errorText = '';
        var aux = $A.get('$Label.c.dict_required');
        aux = aux.replace('<b>', '').replace('</b>','');
        var hasError = false;
        
        /* Checks if the required Price Request fields are not empty */
        if (priceRequest.NeededBy__c == null || priceRequest.NeededBy__c == ''){
            errorText +=$A.get('$Label.c.prequest_needed_by');
            hasError = true;
        }
        if (priceRequest.CurrencyIsoCode == null || priceRequest.CurrencyIsoCode == '') {
            errorText += (hasError == true ? ', ' : '') + $A.get('$Label.c.dict_currency');
            hasError = true;
        } 
        if (hasError == true) {
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), aux.replace('&1', errorText));
        } else {
            helper.submitUpdatePriceRequestAjax(component, priceRequest).then(function(results){
                $A.enqueueAction(component.get('c.collapsePanelHeader'));
            }).catch(function (err) {
                helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            });   
        }
    },
    submitDeclineConfirmation : function(component, event, helper) {
        var itemsSelected = component.get("v.selectedCount");
        var textBodySubmit = $A.get('$Label.c.prequest_decline_confirmation');
        textBodySubmit = textBodySubmit.replace('#NUMITEMS', itemsSelected);
        component.set("v.textConfirmSubmit", textBodySubmit);
        component.set('v.buttonActionSelected', 'DECLINE');
        
        var modal = component.find('modalConfirmSubmit');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
    },
    checkApproveButton : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var itemsSelected = component.get("v.selectedCount");
        var approvedItems = 0;
        
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (listOfAllItems[i].isCheckedApproved == true) {
                approvedItems++;
            }
        }
        
        component.set("v.approveChecked", itemsSelected == approvedItems);
    },
    submitApproveConfirmation : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var passChecks = true;
        
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (listOfAllItems[i].ApprovedPrice__c > listOfAllItems[i].Price__c) {
                passChecks = false;
                helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), $A.get('$Label.c.prequest_price_needed_inferior'));
            } else if (listOfAllItems[i].ApprovedPrice__c < (listOfAllItems[i].Price__c*0.30)) {
                passChecks = false;
                helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), $A.get('$Label.c.prequest_discount_limit'));
            }
        }

        if (passChecks == true){
            var itemsSelected = component.get("v.selectedCount");
            var textBodySubmit = $A.get('$Label.c.dict_approve_confirmation');
            textBodySubmit = textBodySubmit.replace('#NUMITEMS', itemsSelected);
            component.set("v.textConfirmSubmit", textBodySubmit);
            component.set('v.buttonActionSelected', 'APPROVE');
            
            var modal = component.find('modalConfirmSubmit');
            var backdrop = component.find('backdropId');
            $A.util.toggleClass(modal, 'slds-fade-in-open');
            $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        }

    },
    submitDeletePriceRequest : function(component, event, helper) {
        var priceRequest = component.get("v.priceRequest");
        
        helper.submitDeletePriceRequestAjax(component, priceRequest.Id).then(function(results){
            helper.closeComponent(component);
        }).catch(function (err) {
            console.log(err);
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
    },
    /* Change the status of the items to "APPROVED" */
    submitApproved : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var approvedItems = [];
        
        for (var i = 0; i < listOfAllItems.length; i++) {
            listOfAllItems[i].ApprovedPrice__c = parseFloat(listOfAllItems[i].ApprovedPrice__c);
            if (listOfAllItems[i].isChecked == true) {
                if (listOfAllItems[i].ApprovedPrice__c > listOfAllItems[i].Price__c){
                    helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), $A.get('$Label.c.prequest_price_needed_inferior'));
                    exit;
                }
                approvedItems.push(listOfAllItems[i]);
            }
        }
        
        helper.submitApprovedAjax(component, approvedItems).then(function(results){
            helper.reload(component);
        }).catch(function (err) {
            console.log(err);
            console.log(err.message);
            console.log(err.message[0]);
            console.log(err.message[0]['MESSAGE']);
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
    },
    submitDeclined : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var rejectedItems = [];
        
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (listOfAllItems[i].isChecked == true) {
                rejectedItems.push(listOfAllItems[i]);
            }
        }
        
        helper.submitDeclinedAjax(component, rejectedItems).then(function(results){
            helper.reload(component);
        }).catch(function (err) {
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
    },
    /* Depending on the action, shows a message of confirmation */
    handleSubmitConfirmationChecked : function(component, event, helper) {
        var modal = component.find('modalConfirmSubmit');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        var option = component.get("v.buttonActionSelected");
        
        if (option == 'DELETE') {
            $A.enqueueAction(component.get('c.submitDeleteItems'));
        }
        if (option == 'DECLINE') {
            $A.enqueueAction(component.get('c.submitDeclined'));
        }
        if (option == 'APPROVE') {
            $A.enqueueAction(component.get('c.submitApproved'));
        }
        if (option == 'APPROVAL') {
            $A.enqueueAction(component.get('c.submitApproval'));
        }
        if (option == 'DELETEPRICEREQUEST') {
            $A.enqueueAction(component.get('c.submitDeletePriceRequest'));
        }
    },
    closeConfirmationModal : function(component, event, helper) {
        var modal = component.find('modalConfirmSubmit');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        component.set('v.buttonActionSelected', '');
    },
    /* It closes the component, either on a modal, or on an action modal */
    closeComponent : function(component, event, helper) {
        var listOfAllItems = component.get("v.items");
        var disableClose = false;
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (listOfAllItems[i].Status__c == 'NOTSENT') {
                disableClose = true;
            }
        }

        if (disableClose) {
            helper.showWarningMessage(component, $A.get('$Label.c.dict_errorsIntro'), $A.get('$Label.c.prequest_no_close'));
        } else {
            helper.closeComponent(component);
        }
    }
})