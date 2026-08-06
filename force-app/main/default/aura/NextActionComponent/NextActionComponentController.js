({
    onLoad : function(component, event, helper) {
        helper.getLabel(component);         
        if (component.get("v.title") == null ) {
            component.set("v.title", $A.get('$Label.c.dict_guidelines_success'));
        }
    },

    refreshComponent : function(component, event, helper) {
        helper.getLabel(component);         
    },

    swapDivOpen : function(component, event, helper) {
        var actualValue = component.get("v.divOpen");
        if (actualValue == '') {
            component.set("v.divOpen", 'slds-is-open');
        } else {
            component.set("v.divOpen", '');
        }
    },

    labelLoaded : function(component, event, helper) {
        var variant = component.get("v.variant").toUpperCase();
        if (variant == 'TOAST' && component.get("v.labelReference") != null) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: $A.get("$Label.c.dict_status")+" : " + component.get("v.stageName") + " - "+component.get("v.title"),
                message: component.get("v.labelReference"),
                variant: "info",
                duration: 10000
            });
            toastEvent.fire();
        }
    }

})