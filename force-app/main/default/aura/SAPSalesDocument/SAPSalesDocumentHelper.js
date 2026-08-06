({
    getSAPDocument : function(component, docNumber, docType, accountId) {
        var errorList = [];
        component.set("v.errorList", errorList);
        component.set("v.showSpinner", true);
        var action = component.get("c.getSAPDocument");        
        action.setParams({
            docType: docType,
            accountId : accountId,
            docNumber: docNumber
        });
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            // component.set("v.timeUpdated", new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
            var state = response.getState();
            var serverResponse = response.getReturnValue();            
            if(state === "SUCCESS"){
                if (serverResponse) {
                    this.prepareDataTable(component, serverResponse);
                    this.setDescriptions(component, serverResponse);
                    this.setReps(component, serverResponse);
                    serverResponse.statusName = serverResponse.statusName.toUpperCase();
                    component.set("v.sapdoc", serverResponse);
                    component.set("v.accountUrl", "/lightning/r/" + serverResponse.accountId + "/view");
                    component.set("v.soldToUrl", "/lightning/r/" + serverResponse.soldToId + "/view");
                    if (serverResponse.opportunityName) {
                        component.set("v.opportunityURL", "/lightning/r/" + serverResponse.opportunity + "/view");
                    }
                } else {
                    var errors = [];
                    var error = new Object();
                    error.message = $A.get('$Label.c.dict_msg_oops');
                    errors.push(error);
                    this.handleErrors(component, errors);    
                }
            } else if(state === "INCOMPLETE"){                
            } else if(state === "ERROR"){                    
                this.handleErrors(component, response.getError());
            }            
        }); 
        $A.enqueueAction(action);
    },

    downloadDocument : function(component, docType, docNumber) {
        var errorList = [];
        component.set("v.errorList", errorList);
        component.set("v.showSpinner", true);
        var action = component.get("c.downloadSAPDocument");        
        /*if (docType.toUpperCase() == 'I') {
            docNumber = '6220100015';
        }*/
        action.setParams({
            docType: docType,
            docNumber: docNumber
        });
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            var serverResponse = response.getReturnValue();                        
            if (state === "SUCCESS") {
                if (serverResponse.success) {
                    this.download(docNumber + ".pdf", serverResponse.json);
                } else {
                    var message = $A.get('$Label.c.saps_msg_002') + '\n\n [' + serverResponse.code + '] ' + serverResponse.message;
                    this.showError(component, "error", "Error", message);
                }
            } else if(state === "INCOMPLETE"){                
            } else if(state === "ERROR"){                    
                this.handleErrors(component, response.getError());
            }            
        }); 
        $A.enqueueAction(action);
    },

    download : function(filename, content) {
        var binaryString = window.atob(content);
        var binaryLen = binaryString.length;
        var bytes = new Uint8Array(binaryLen);
        for (var i = 0; i < binaryLen; i++) {
           var ascii = binaryString.charCodeAt(i);
           bytes[i] = ascii;
        }        
        var blob = new Blob([bytes], {type: "application/pdf"});
        var link = document.createElement('a');
        link.href = window.URL.createObjectURL(blob);
        link.download = filename;
        link.click();
    },

    prepareDataTable : function(component, sapdoc) {
        component.set('v.columns', [
            {label: $A.get('$Label.c.dict_lineNo'), fieldName: 'docLine', type: 'number'},
            {label: $A.get('$Label.c.dict_product'), fieldName: 'SKU', type: 'text'},
            {label: $A.get('$Label.c.dict_productName'), fieldName: 'name', type: 'text'},
            {label: $A.get('$Label.c.dict_quantity'), fieldName: 'quantity', type: 'Number'},
            {label: $A.get('$Label.c.dict_unit'), fieldName: 'unitCode', type: 'Text'},
            {label: $A.get('$Label.c.saps_hdr_net'), fieldName: 'net', type: 'currency', typeAttributes: { currencyCode: sapdoc.curr}},
            {label: '', fieldName: 'dummy', hideDefaultActions: true, fixedWidth: 16 }
        ]);
    },

    setDescriptions : function(component, sapdoc) {
        var subtitle = '';
        if (sapdoc.salesOrgName) {
            subtitle = '[' + sapdoc.salesOrg + '] ' + sapdoc.salesOrgName;                 
            subtitle += ' · [' + sapdoc.distChannel + '] ' + sapdoc.distChannelName;                             
        } else {
            subtitle = 'Sales Organisation ' + sapdoc.salesOrg;
            subtitle += ' · Distribution Channel ' + sapdoc.distChannel;
        }
        var salesOffice = '---';
        if (sapdoc.salesOffice) {
            if (sapdoc.salesOfficeName) {
                salesOffice = ']' + sapdoc.salesOffice + '] ' + sapdoc.salesOfficeName;
            } else {
                salesOffice = 'Sales office ' + sapdoc.salesOffice;
            }            
        }
        component.set("v.subtitle", subtitle);
        component.set("v.salesOffice", salesOffice);
        component.set("v.description", sapdoc.typeDescription);
    },

    setReps : function(component, sapdoc) {
        if (sapdoc.rep1) {
            component.set("v.rep1URL", "/lightning/r/" + sapdoc.rep1 + "/view");
        } else {
            if (sapdoc.sapRep1) {
                component.set("v.rep1Name", 'SAP rep ' + sapdoc.sapRep1 + ' not mapped');
            } else {
                component.set("v.rep1Name", '---');
            }
        }
        if (sapdoc.rep2) {
            component.set("v.rep2URL", "/lightning/r/" + sapdoc.rep2 + "/view");
        } else {
            if (sapdoc.sapRep2) {
                component.set("v.rep2Name", 'SAP id ' + sapdoc.sapRep2 + ' (not mapped)');
            } else {
                component.set("v.rep2Name", '---');
            }
        }
    },

    handleErrors : function(component, errors) {
        var errorList = [];
        if (errors && Array.isArray(errors) && errors.length > 0) {
            for (var i=0; i<errors.length;i++) {
                errorList.push(errors[i].message);
            }
            component.set("v.errorList", errorList);
        }
    }, // handleErrors

    showError : function(component, type, title, message) {
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": "Something has gone wrong!",
            "message": message
        });        
    },  

    customiseForm : function(component, docType) {
        // Defaults
        var iconType = 'standard:orders';
        var titleType = $A.get('$Label.c.dict_orders');
        var description = $A.get('$Label.c.dict_order');                
        switch (docType.toUpperCase()) {
            case 'Q':
                iconType = 'standard:quotes';
                titleType = $A.get('$Label.c.dict_quotes');
                description = $A.get('$Label.c.dict_quote');
                break;            
            case 'I': 
                iconType = 'standard:timesheet';
                titleType = $A.get('$Label.c.dict_invoices');
                description = $A.get('$Label.c.dict_invoice');
                break;             
        } // switch        
        component.set('v.iconType', iconType);
        component.set('v.titleType', titleType);
        component.set('v.description', description);
    }

})