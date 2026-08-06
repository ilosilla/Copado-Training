({
	onLoad : function(component, event, helper) {
        component.find("selectFilter").set("v.value", 'ACTIVE');
        helper.setSummaryColumns(component);
        helper.getComponentData(component);
    },
    onChangeFilter : function(component, event, helper) {
    	helper.filterList(component);
	},
    handleRefresh : function(component, event, helper) {
        helper.getComponentData(component);
    }
})