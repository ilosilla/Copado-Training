({
    CloseModal : function(component, event, helper) {
        console.log("close Modal");
        $A.get("e.force:closeQuickAction").fire();
    },
})