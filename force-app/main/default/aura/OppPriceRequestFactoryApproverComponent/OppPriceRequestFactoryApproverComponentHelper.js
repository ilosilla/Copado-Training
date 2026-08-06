({
    /* Get all data needed: Price Request List, Sales Orgs and Sales Offices */
    getData: function(component) {
        var aux = this;
        var transformedList = [];
        Promise.all([aux.getSalesOrgsListAjax(component), aux.getSalesOfficesListAjax(component), aux.getHeadersListAjax(component) ]).then(function(results) {
            var salesOrgs = results[0];
            var salesOffices = results[1];
            var headers = results[2];
            component.set("v.salesOrgsList", salesOrgs);
            component.set("v.salesOfficesList", salesOffices);
            component.set("v.showPage", true);

            /* We transform the list so we can show what we want and the way we want */
            headers.forEach(function(elem) {
                var auxItem = {};
                auxItem.Needed = elem.NeededBy__c; 
                auxItem.OpportunityUrl = '/lightning/r/Opportunity/' + elem.Opportunity__r.Id + '/view';
                auxItem.AccountUrl = '/lightning/r/Account/' + elem.Opportunity__r.AccountId + '/view';
                auxItem.OpportunityName = elem.Opportunity__r.Name;
                auxItem.AccountName = elem.Opportunity__r.Account.Name;
                auxItem.OwnerName = elem.Opportunity__r.Owner.Name;
                auxItem.OwnerMail = elem.Opportunity__r.Owner.Email;
                auxItem.CreatedDate = elem.CreatedDate;
                auxItem.Status = elem.Status__c;
                
                if (salesOffices[elem.Opportunity__r.Owner.Sales_Office__c] != null && salesOffices[elem.Opportunity__r.Owner.Sales_Office__c] != 'undefined'){
                    auxItem.OwnerSalesOffice = salesOffices[elem.Opportunity__r.Owner.Sales_Office__c].Name;
                } else {
                    auxItem.OwnerSalesOffice = elem.Opportunity__r.Owner.Sales_Office__c;
                }
                
                if (salesOrgs[elem.Opportunity__r.Owner.Default_Sales_Organization__c] != null && salesOrgs[elem.Opportunity__r.Owner.Default_Sales_Organization__c] != 'undefined'){
                    auxItem.OwnerSalesOrg = salesOrgs[elem.Opportunity__r.Owner.Default_Sales_Organization__c].Name;
                } else {
                    auxItem.OwnerSalesOrg = elem.Opportunity__r.Owner.Default_Sales_Organization__c;   
                }
                // auxItem.ItemsToManage = elem.PendingItems__c;
                auxItem.Id = elem.Id;
                auxItem.OpportunityId = elem.Opportunity__r.Id;
                
                transformedList.push(auxItem);
            });
            aux.setColumns(component);
            component.set("v.headersList", transformedList);
            component.set("v.showSpinner", false);
        });
        /*aux.getSalesOrgsListAjax(component).then(function(salesOrgs){
            component.set("v.salesOrgsList", salesOrgs);
            aux.getSalesOfficesListAjax(component).then(function(salesOffices){
                component.set("v.salesOfficesList", salesOffices);
                
                aux.getHeadersListAjax(component).then(function(headers){
                    component.set("v.showPage", true);
                    
                    //We transform the list so we can show what we want and the way we want 
                    headers.forEach(function(elem) {
                        console.log(elem);
                        var auxItem = {};
                        auxItem.Needed = elem.NeededBy__c; 
                        auxItem.OpportunityUrl = '/lightning/r/Opportunity/' + elem.Opportunity__r.Id + '/view';
                        auxItem.AccountUrl = '/lightning/r/Account/' + elem.Opportunity__r.AccountId + '/view';
                        auxItem.OpportunityName = elem.Opportunity__r.Name;
                        auxItem.AccountName = elem.Opportunity__r.Account.Name;
                        auxItem.OwnerName = elem.Opportunity__r.Owner.Name;
                        auxItem.OwnerMail = elem.Opportunity__r.Owner.Email;
                        auxItem.CreatedDate = elem.CreatedDate;
                        auxItem.Status = elem.Status__c;
                        
                        if (salesOffices[elem.Opportunity__r.Owner.Sales_Office__c] != null && salesOffices[elem.Opportunity__r.Owner.Sales_Office__c] != 'undefined'){
                            auxItem.OwnerSalesOffice = salesOffices[elem.Opportunity__r.Owner.Sales_Office__c].Name;
                        } else {
                            auxItem.OwnerSalesOffice = elem.Opportunity__r.Owner.Sales_Office__c;
                        }
                        
                        if (salesOrgs[elem.Opportunity__r.Owner.Default_Sales_Organization__c] != null && salesOrgs[elem.Opportunity__r.Owner.Default_Sales_Organization__c] != 'undefined'){
                            auxItem.OwnerSalesOrg = salesOrgs[elem.Opportunity__r.Owner.Default_Sales_Organization__c].Name;
                        } else {
                            auxItem.OwnerSalesOrg = elem.Opportunity__r.Owner.Default_Sales_Organization__c;   
                        }
                        // auxItem.ItemsToManage = elem.PendingItems__c;
                        auxItem.Id = elem.Id;
                        auxItem.OpportunityId = elem.Opportunity__r.Id;
                        
                        transformedList.push(auxItem);
                    });
                    aux.setColumns(component);
                    component.set("v.headersList", transformedList);
                    component.set("v.showSpinner", false);
                }).catch(function (err) {
                    aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
                });
            }).catch(function (err) {
                aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
            });
        }).catch(function (err) {
            aux.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });*/
    },
    setColumns : function(component) {
        component.set('v.columns', [
            {label: $A.get("$Label.c.dict_status"), sortable: false, fieldName: 'Status', hideDefaultActions : true, type: 'text', cellAttributes: { alignment: 'center' }},
            {label: $A.get("$Label.c.dict_created"), sortable: true, fieldName: 'CreatedDate', hideDefaultActions : true, type: 'date', cellAttributes: { alignment: 'center' }},
            {label: $A.get("$Label.c.dict_opportunity"), sortable: false, fieldName: 'OpportunityUrl', hideDefaultActions : true, type: 'url', cellAttributes: { alignment: 'center' }, typeAttributes: { label: {fieldName: 'OpportunityName'}}},
            {label: $A.get("$Label.c.dict_owner"), sortable: false, fieldName: 'OwnerMail', hideDefaultActions : true, type: 'email', cellAttributes: { alignment: 'center' }},
            {label: $A.get("$Label.c.dict_salesOrg"), sortable: false, fieldName: 'OwnerSalesOrg', hideDefaultActions : true, type: 'text', cellAttributes: { alignment: 'center' }},
            {label: $A.get("$Label.c.dict_sales_office"), sortable: false, fieldName: 'OwnerSalesOffice', hideDefaultActions : true, type: 'text', cellAttributes: { alignment: 'center' }},
            {label: $A.get("$Label.c.dict_account"), sortable: false, fieldName: 'AccountUrl', hideDefaultActions : true, type: 'url', cellAttributes: { alignment: 'center' }, typeAttributes: { label: {fieldName: 'AccountName'}}},
            {label: $A.get("$Label.c.prequest_needed_by"), sortable: true, fieldName: 'Needed', hideDefaultActions : true, type: 'date', cellAttributes: { alignment: 'center' }},
            {type: "button", sortable: false, fixedWidth: 140, typeAttributes: { label: 'Approve', name: 'approve', title: 'Approve', disabled: false, value: 'approve'}},
        ]);
    },
    sortData : function(component, fieldName, direction) {
        var listHeaders = component.get("v.headersList");
            if (direction == 'asc') {
            	listHeaders.sort((a,b) => (a[fieldName] > b[fieldName] ? 1: -1));
            } else {
            	listHeaders.sort((a,b) => (a[fieldName] < b[fieldName] ? 1: -1));
            }
 		component.set("v.headersList", listHeaders);
		component.set('v.sortDirection', direction);
        component.set('v.sortedBy', fieldName);
    },
    /************************* AJAX CALLS ********************************/
    getHeadersListAjax : function(component) {
        var action = component.get("c.getFactoryHeadersList");
        return this.returnPromiseAjax(action);
    },
    getSalesOrgsListAjax : function(component) {
        var action = component.get("c.getSalesOrgs");
        return this.returnPromiseAjax(action);
    },
    getSalesOfficesListAjax : function(component) {
        var action = component.get("c.getSalesOffices");
        return this.returnPromiseAjax(action);
    },
    getPermissionsAjax : function(component) {
        var action = component.get("c.getGeneralPermissions");
        return this.returnPromiseAjax(action);
    },
    /********* Global methods *************/
    showErrorMessage : function(component, title, body) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: body,
            type: "error"
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