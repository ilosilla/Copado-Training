({
    doInit : function(component, event, helper) {
        //console.log("update 14");
        
        helper.getPicklistSalesOrg(component);
        //console.log('hasSapId: ' + component.get("v.hasSapId"));
    },
    
    handleChangeSalesOrg : function(component, event, helper) {
        let salesOrgCmp = event.getSource();
        //console.log("handleChangeSalesOrg: " + salesOrgCmp.get("v.value"));
        
        if( helper.pintarCombobox(component, salesOrgCmp) ){
            helper.getTableInformation(component, salesOrgCmp.get("v.value"));
        }
        
    },
    
    handleRefresh : function(component, event, helper) {
    	let salesOrgCmp =  component.find("salesOrg");
        
        if( helper.pintarCombobox(component, salesOrgCmp) ){
            helper.getTableInformation(component, salesOrgCmp.get("v.value"));
        }
        
    },
})