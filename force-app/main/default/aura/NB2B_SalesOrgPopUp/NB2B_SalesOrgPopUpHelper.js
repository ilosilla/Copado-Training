({
    managePopUpVisibility : function(component, requestFailed) {
        const salesRelId = window.sessionStorage.getItem('salesOrgId');
        console.log('NB2B_SalesOrgPopUpController - managePopUpVisibility() - salesRelId:', salesRelId);
        const salesList = component.get('v.salesList');
        const salesRelIsActive = salesList.findIndex(salesRel => salesRel.Id===salesRelId) > -1;

        if(
            salesRelId != null &&
            salesList &&
            salesList.length>0 &&
            salesRelIsActive
        ){
            this.setContactSalesOrg(component, salesRelId);
            // YA TENEMOS CARGADO EL SALES ORGANIZATION Y ESTÁ ACTIVO
        }else{
            console.log('NB2B_SalesOrgCmpController - doInit() - [SHOW SELECTOR]');
            //SHOW SELECTOR
            if(salesList.length > 1){
                component.set('v.showSelector', true);
            }else if(salesList.length === 1){
                this.setSessionSalesOrg(salesList[0]);
                component.set('v.showSelector', false);
            }else if(salesList.length === 0 || requestFailed){
                this.setSessionSalesOrg({
                    Name: 'fault',
                    Id: 'fault',
                    Sales_Org__c: 'fault',
                });
                component.set('v.showSelector', false);
            }
        }
    },
    setSessionSalesOrg : function(salesOrgWr) {
        window.sessionStorage.setItem('salesOrgName', salesOrgWr.Name);
        window.sessionStorage.setItem('salesOrgCode', salesOrgWr.Sales_Org__c);
        window.sessionStorage.setItem('salesOrgId', salesOrgWr.Id);
    },

    setContactSalesOrg: function(component, salesOrgWrId) {
        try{

       
        console.log("Contact SalesOrg:" + salesOrgWrId);

        var action = component.get("c.saveContactSalesOrg");
        action.setParams({
            salesOrgId: salesOrgWrId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Contact SalesOrg updated successfully");
            }else{
                console.log("Error : " + response);
            }
        });
        
        $A.enqueueAction(action);
        }
        catch(e){console.error(e); }
    },
})