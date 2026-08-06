({
	doInit : function(component, event, helper) {
        var data = window.sessionStorage.getItem('salesOrgId');
        if(data != null && data != 'undefined'){
            //YA TENEMOS CARGADO EL SALES ORGANIZATION
            component.set('v.salesName' , window.sessionStorage.getItem('salesOrgName'));
        }else{
            component.set('v.showSelector', true);
            //SHOW SELECTOR
        }
	},
    onValueChange : function(component, event, helper) {
       var sales = component.get('v.NB2B_SalesOrg');
       window.sessionStorage.setItem('salesOrgName',sales.Name);
       window.sessionStorage.setItem('salesOrgCode',sales.Sales_Org__c);
       window.sessionStorage.setItem('salesOrgId',sales.Id);
        component.set('v.salesName' , sales.Name);
        component.set('v.showSelector', false);
	}
})