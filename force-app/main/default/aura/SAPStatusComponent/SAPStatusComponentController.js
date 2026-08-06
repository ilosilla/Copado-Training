({
    onLoad : function(component, event, helper) {
        helper.setSummaryColumns(component, '');
        helper.getComponentData(component);
    },
    handleRefresh : function(component, event, helper) {
        component.set("v.summaryData", []);
        helper.getComponentData(component);
    },
    getSAPCredit :  function(component, event, helper) {
        helper.getSAPCredit(component);
    },
    salesOrgChanged :  function(component, event, helper) {
        helper.resetPanels(component);
        helper.getComponentData(component);
    },
    handleRefreshCredit :  function(component, event, helper) {
        helper.resetPanels(component);
        helper.getSAPCredit(component);
    },
    carouselClick : function(component, event, helper) {
        var clicked = event.currentTarget.id;
        var panels = component.find("carousel-panels");        
        var dots = component.find("carousel-indicators").getElement().childNodes;
        var selected = -1;
        for (var i = 0; i<dots.length; i++) {
            var node = dots.item(i).firstElementChild;
            if (node.id == clicked) {
                $A.util.addClass(node, 'slds-is-active');
                $A.util.addClass(panels, 'transform' + i);
                selected = i;
            } else {
                $A.util.removeClass(node, 'slds-is-active');
                $A.util.removeClass(panels, 'transform' + i);
            }
        }
        if (selected == 1) {
            var subtitle = component.get('v.subtitle2');
            var agedOrders = component.get("v.agedOrders");
            if (agedOrders == null || agedOrders.length == 0) {
                helper.getOrdersHistory(component);
            } else {
                component.set("v.currentTitle", $A.get("$Label.c.dict_agedOrders"));
            }
        } else {
            subtitle = component.get('v.subtitle1');
            component.set("v.currentTitle", $A.get("$Label.c.dict_openDocuments"));
        }
        component.set('v.statusText', subtitle);
    }
})