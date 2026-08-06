({
    init : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var onModal = component.get("v.componentOnModal");
        var textWarning = '';
        
        /* We check the user permissions (user's context and if it's an approver) */
        helper.getPermissionsAjax(component).then(function(permissions){
            component.set("v.isActive", permissions.isEnabled && permissions.isFactoryApprover);
            component.set("v.approverMode", permissions.isFactoryApprover);
            if (permissions.isEnabled == false) {
                /* Not enabled on user's context */
                component.set("v.showPage", true);
                component.set("v.textWarning", $A.get('$Label.c.dict_msg_not_available_yet'));
                component.set("v.showSpinner", false);
            } else if (permissions.isFactoryApprover == false) {
                /* Not an approver */
                component.set("v.showPage", true);
                component.set("v.textWarning", $A.get('$Label.c.dict_msg_no_access'));
                component.set("v.showSpinner", false);
            } else {
                /* The user has all permissions needed */
                helper.getData(component);
            }
        }).catch(function (err) {
            helper.showErrorMessage(component, $A.get('$Label.c.dict_errorsIntro'), err.message);
        });
    },
    /* Opens the Price Request selected */
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'approve':
                component.set("v.selectedPriceRequest", row.OpportunityId);
                var modal = component.find('modalPriceRequest');
                var backdrop = component.find('backdropId');
                $A.util.toggleClass(modal, 'slds-fade-in-open');
                $A.util.toggleClass(backdrop, 'slds-backdrop_open');
                break;
        }
    },
    closeModal: function (component, event, helper) {
        var modal = component.find('modalPriceRequest');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        component.set("v.selectedPriceRequest", '');
        $A.enqueueAction(component.get('c.init'));
    },
    closeModalHistoric: function (component, event, helper) {
        var modal = component.find('modalPriceRequestHistoric');
        var backdrop = component.find('backdropId');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        component.set("v.selectedPriceRequest", '');
        $A.enqueueAction(component.get('c.init'));
    },
    sortRows: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        console.log(fieldName);
        console.log(sortDirection);
        console.log('-----------------------------');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
})