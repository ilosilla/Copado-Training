/* eslint-disable padding-line-between-statements */
/* eslint-disable no-unused-vars */
// eslint-disable-next-line no-unused-expressions
({
    onLoadPage : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.buildPage(component);
    },

    handleNextClick : function(component, event, helper) {
        event.preventDefault();
        helper.openCaseForm(component);
    },

    handleCancelClick : function(component, event, helper) {
        helper.closeTab(component);
    }

})