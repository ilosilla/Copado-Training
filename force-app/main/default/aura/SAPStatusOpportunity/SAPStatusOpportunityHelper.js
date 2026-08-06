({
    getComponentData : function(component) {
        var errorList = [];
        component.set("v.errorList", errorList);
        component.set("v.spinner", true);
        component.set("v.disable", true);
        var action = component.get("c.getComponentData");        
        action.setParams({
            oppId : component.get("v.recordId")
        });    
        action.setCallback(this, response => this.getComponentCallback(component, response));                
        $A.enqueueAction(action);
    }, // getComponentData

    getComponentCallback : function (component, response) {
        var strStatus =  $A.get('$Label.c.dict_updatedAt');
        strStatus = strStatus.replace('&1', new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
        component.set("v.statusText", strStatus);
        component.set("v.subtitle1", strStatus);   
        component.set("v.spinner", false);
        component.set("v.disable", false);

        var state = response.getState();
        var dto = response.getReturnValue();
        if(state === "SUCCESS"){ 
            this.transformDataForScreen(component, dto);
            /*
            this.setSummaryColumns(component, dto.curr);
            component.set("v.disable", false);
            component.set("v.componentEnabled", dto.enabled);
            component.set("v.orgOptions", dto.salesOrgs);
            component.set("v.selectedOrg", dto.defaultOrg);
            component.set("v.summaryData", dto.documents);
            component.set("v.sapId", dto.sapId);
            */
        } else if(state === "INCOMPLETE") {                
        } else if(state === "ERROR") {                    
            this.handleErrors(component, response.getError());
        }            
    }, // getComponentCallback

    transformDataForScreen : function(component, dto) {

        var sapData = [];

        var quotes = new Object();
        quotes.url = '/lightning/cmp/c__sapdocs?c__t=q&c__opp=' + dto.opportunityId;        
        quotes.title = $A.get('$Label.c.dict_quotes');
        quotes.total = dto.quotesTotal;
        quotes.number = dto.numQuotes;
        quotes.lastDoc = dto.lastQuote;
        quotes.curr = dto.curr;
        quotes.footNote = true;
        sapData.push(quotes);

        var orders = new Object();
        orders.url = '/lightning/cmp/c__sapdocs?c__t=o&c__opp=' + dto.opportunityId;        
        orders.title = $A.get('$Label.c.dict_orders');
        orders.total = dto.ordersTotal;
        orders.number = dto.numOrders;
        orders.lastDoc = dto.lastOrder;
        orders.curr = dto.curr;
        orders.footNote = false;
        sapData.push(orders);

        var invoices = new Object();
        invoices.url = '/lightning/cmp/c__sapdocs?c__t=i&c__opp=' + dto.opportunityId;
        invoices.title = $A.get('$Label.c.dict_invoices');
        invoices.total = dto.invoicesTotal;
        invoices.number = dto.numInvoices;
        invoices.lastDoc = dto.lastInvoice;
        invoices.curr = dto.curr;
        invoices.footNote = false;
        sapData.push(invoices);

        component.set('v.sapData', sapData);   
        
        var salesOrgs = [];
        for (var i = 0; i < dto.salesOrgs.length; i++) {
            var o = new Object();
            o.name = dto.salesOrgs[i];
            o.permission = dto.permission[i];
            salesOrgs.push(o);
        }
        component.set("v.orgs", salesOrgs);
    },
    
    handleErrors : function(component, errors) {
        var errorList = [];
        if (errors && Array.isArray(errors) && errors.length > 0) {
            for (var i=0; i<errors.length;i++) {
                errorList.push(errors[i].message);
            }
            component.set("v.errorList", errorList);
        }
    } // handleErrors
});