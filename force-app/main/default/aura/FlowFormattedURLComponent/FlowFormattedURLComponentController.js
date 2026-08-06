({
    init : function (component, event, helper) {
        var cssString = component.get("v.cssString");
        var theme = component.get("v.theme");        
        cssString +=  " slds-theme_" + theme.toLowerCase();
        component.set("v.cssString", cssString);
    } // getStyle    
})