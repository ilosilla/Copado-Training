({
    getComponentData : function(cmp) {
        var errorList = [];
        cmp.set("v.errorList", errorList);
        cmp.set("v.spinner", true);
        cmp.set("v.disable", true);
        var action = cmp.get("c.getComponentData");        
        action.setParams({
            accountId : cmp.get("v.recordId"),
            salesOrg: cmp.get('v.selectedOrg')
        });        
        action.setCallback(this, function(response) {
            var strStatus =  $A.get('$Label.c.dict_updatedAt');
            strStatus = strStatus.replace('&1', new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
            cmp.set("v.currentTitle", $A.get("$Label.c.dict_openDocuments"));
            cmp.set("v.statusText", strStatus);
            cmp.set("v.subtitle1", strStatus);   
            cmp.set("v.spinner", false);
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            if(state === "SUCCESS"){                    
                var dto = serverResponse;    
                this.setSummaryColumns(cmp, dto.curr);
                cmp.set("v.disable", false);
                cmp.set("v.componentEnabled", dto.enabled);
                cmp.set("v.orgOptions", dto.salesOrgs);
                cmp.set("v.selectedOrg", dto.defaultOrg);
                cmp.set("v.summaryData", dto.documents);
                cmp.set("v.sapId", dto.sapId);
            } else if(state === "INCOMPLETE") {                
            } else if(state === "ERROR") {                    
                this.handleErrors(cmp, response.getError());
            }            
        });         
        $A.enqueueAction(action);
    },

    getSAPCredit : function(component) {
        var errorList = [];    
        component.set("v.spinner", true);
        var action = component.get("c.getSAPCreditData");        
        action.setParams({
            sapId : component.get("v.sapId"),
            salesOrg: component.get('v.selectedOrg')
        });        
        action.setCallback(this, function(response) {            
            var state = response.getState();
            if(state === "SUCCESS"){                    
                var dto = response.getReturnValue();    
                var creditInfo = {};
                creditInfo.companyName = dto.company_name;
                creditInfo.terms = '[' + dto.payment_terms + '] ' + dto.terms_name;
                creditInfo.creditGroup = '[' + dto.risk_category + '] ' + dto.risk_name;
                creditInfo.creditLimit = dto.credit_limit;
                creditInfo.currency = dto.currency;
                creditInfo.creditAvailable = dto.credit_available;
                creditInfo.creditExposure = dto.risk_exposure;
                creditInfo.globalBalance = dto.balance_to_pay - dto.balance_to_refund;
                creditInfo.openOrders = dto.totals.open_orders;
                creditInfo.openDeliveries = dto.totals.open_deliveries;
                creditInfo.closedDeliveries= dto.totals.closed_deliveries;
                creditInfo.openItems = dto.totals.open_items;
                creditInfo.overdueItems = dto.totals.overdue_items;
                creditInfo.deposits = dto.totals.deposits;
                creditInfo.block = dto.block;
                this.calcStatus(creditInfo);                
                component.set("v.creditInfo", creditInfo);
                var dtarget = component.find('creditSummary');
                $A.util.removeClass(dtarget, 'slds-theme_success');            
                $A.util.removeClass(dtarget, 'slds-theme_warning');    
                if (creditInfo.block) {
                    $A.util.addClass(dtarget, 'slds-theme_error');                    
                } else if (creditInfo.error || creditInfo.warning) {
                    $A.util.addClass(dtarget, 'slds-theme_warning');                    
                } else {
                    $A.util.addClass(dtarget, 'slds-theme_shade');                    
                }
                var button = component.find('creditButton');
                var container = component.find('creditContainer');
                $A.util.addClass(button, 'slds-hide');                                    
                $A.util.removeClass(container, 'slds-hide');                                    
            } else if(state === "ERROR"){                    
                this.notifyErrors(component, response.getError());
            }    
            component.set("v.spinner", false);
        });         
        $A.enqueueAction(action);
    },

    getOrdersHistory : function(component) {
        var errorList = [];    
        component.set("v.spinner", true);
        var action = component.get("c.getOrdersHistory");        
        action.setParams({
            sapId : component.get("v.sapId"),
            salesOrg: component.get('v.selectedOrg')
        });        
        action.setCallback(this, function(response) {      
            var strStatus = $A.get('$Label.c.dict_updatedAt');
            strStatus = strStatus.replace('&1', new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
            component.set("v.currentTitle", $A.get("$Label.c.dict_agedOrders"));
            component.set("v.statusText", strStatus);
            component.set("v.subtitle2", strStatus);                  
            var state = response.getState();
            if(state === "SUCCESS") {                    
                var orders = response.getReturnValue();  
                component.set("v.agedOrders", orders);
             } else if(state === "ERROR") {                    
                this.notifyErrors(component, response.getError());
             }
            component.set("v.spinner", false);
        });         
        $A.enqueueAction(action);
    }, // getOrdersHistory

    resetPanels : function(component) {
        var button = component.find('creditButton');
        var container = component.find('creditContainer');
        $A.util.removeClass(button, 'slds-hide');                                    
        $A.util.addClass(container, 'slds-hide');                                    
    },

    calcStatus : function(creditInfo) {
        var str = '';
        creditInfo.error = false;
        creditInfo.warning = false;
        creditInfo.globalText = $A.get('$Label.c.saps_zcli_balance');
        if (creditInfo.globalBalance > 0) {
            creditInfo.globalText = $A.get('$Label.c.saps_zcli_ourbalance');// 'GLOBAL BALANCE IN OUR FAVOR:';
        }
        if (creditInfo.globalBalance < 0) {
            creditInfo.globalText =  $A.get('$Label.c.saps_zcli_custbalance'); // 'GLOBAL BALANCE IN CUSTOMER\'S FAVOR:';
            creditInfo.globalBalance = - creditInfo.globalBalance;
        }
        if (creditInfo.block) {
            creditInfo.error = true;
            creditInfo.summaryTitle =  $A.get('$Label.c.saps_zcli_crproblem');      //  CREDIT PROBLEM
            creditInfo.summaryText =  $A.get('$Label.c.saps_zcli_blocked');         // 'Customer is blocked by credit
        } else if (creditInfo.overdueItems > 0) {
            creditInfo.error = true;
            creditInfo.summaryTitle = $A.get('$Label.c.saps_zcli_crproblem');       // CREDIT PROBLEM
            str = $A.get('$Label.c.saps_zcli_overdue');                             // Customer has overdue items for a value of
            str = str.replace('&1', creditInfo.overdueItems);
            creditInfo.summaryText = str.replace('&2', creditInfo.currency);
        } else if (creditInfo.creditAvailable < 0) {
            creditInfo.error = true;
            creditInfo.summaryTitle = $A.get('$Label.c.saps_zcli_crproblem');       // CREDIT PROBLEM
            str = $A.get('$Label.c.saps_zcli_overrun');                             // Credit limit overrun by
            str = str.replace('&1', creditInfo.overdueItems);
            creditInfo.summaryText = str.replace('&2', creditInfo.currency);
        } else if (creditInfo.creditLimit > 0 && creditInfo.creditExposure == 0) {
            creditInfo.warning = true;
            creditInfo.summaryTitle = $A.get('$Label.c.saps_zcli_crwarning');       // CREDIT WARNING
            creditInfo.summaryText =  $A.get('$Label.c.saps_zcli_nocredit');        // No credit available
        } else {
            creditInfo.summaryTitle = $A.get('$Label.c.saps_zcli_crok');            // CREDIT OK
            creditInfo.summaryText = $A.get('$Label.c.saps_zcli_noissues');         // No credit issues detected
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

    notifyErrors : function(component, errors) {
        var errorString = $A.get('$Label.c.saps_zcli_error1') + '\n\n';
        if (errors && Array.isArray(errors) && errors.length > 0) {
            for (var i=0; i<errors.length;i++) {
                errorString += '- ' + errors[i].message + '\n';
            }
        }
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": "SAP Service Error",
            "message": errorString
        });        
    }, // notifyErrors

    setSummaryColumns : function(component, currCode) {
        var col1 = '{!$Label.c.saps_hdr_docType}';
        component.set('v.summaryColumns', [            
            {
                label: $A.get('$Label.c.saps_hdr_docType'), fieldName: 'url', 
                type: 'url',
                typeAttributes: { label: {fieldName: 'docType'}},
                cellAttributes: {class: 'text-bold'},
                target : '_subtab'
            },
            {label: $A.get('$Label.c.saps_hdr_salesOrg'), fieldName: 'salesOrg', type: 'text', cellAttributes: {alignment: 'center'}},
            {label: $A.get('$Label.c.saps_hdr_net'), fieldName: 'net', type: 'currency', typeAttributes: { currencyCode: currCode, currencyDisplayAs: 'symbol' }},            
            {label: $A.get('$Label.c.saps_hdr_tax'), fieldName: 'tax', type: 'currency', typeAttributes: { currencyCode: currCode, currencyDisplayAs: 'symbol' }},            
            {label: $A.get('$Label.c.saps_hdr_total'), fieldName: 'total', type: 'currency', typeAttributes: { currencyCode: currCode, currencyDisplayAs: 'symbol' }},            
            {label: $A.get('$Label.c.saps_hdr_lastDoc'), fieldName: 'lastDoc', type: 'date', cellAttributes: {alignment: 'center'}},
            {label: $A.get('$Label.c.saps_hdr_numDocs'), fieldName: 'count', type: 'integer', cellAttributes: {alignment: 'right'}}
        ]);
    }
})