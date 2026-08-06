({
    /**
     * Assigns the css string to the corresponding type pf message
     */
    getStyle : function(component, event, helper) {
        var cssString = component.get("v.cssString");
        var type = component.get("v.type");
        cssString +=  " slds-theme_" + type.toLowerCase();
        component.set("v.cssString", cssString);
        component.set("v.heading", helper.getHeader(type));        
    } // getStyle      
    
})