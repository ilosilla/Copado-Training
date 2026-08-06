({
    init : function(component, event, helper) {
        helper.getAllDataAjax(component, component.get("v.recordId")).then(function(result){
            console.log('AAAAA')
            console.log(result)
            component.set("v.priceRequest", result.headerData);
            component.set("v.isStoreManager", result.permissions.isStoreManager);
            component.set("v.isFactoryManager", result.permissions.isFactoryManager);
            component.set("v.isStoreApprover", result.permissions.isStoreApprover);
            component.set("v.isFactoryApprover", result.permissions.isFactoryApprover);
            component.set("v.isActive", result.permissions.isEnabled);
            helper.setTitles(component);
            component.set("v.showSpinner", false);
        }).catch(function (err) {
             console.log(err);
            helper.showErrorMessage(component, "Error!", err.message);
        });
    },
    toggleModal : function(component, event, helper) {
        var componentShowing = component.get("v.showComponent");
        if (componentShowing == true) {
            component.set("v.showComponent", false);
           	$A.enqueueAction(component.get('c.init'));
        } else {
            component.set("v.showComponent", true);
            $A.enqueueAction(component.get('c.init'));
        }
        var modal = component.find('modalPriceRequest');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
    }
})