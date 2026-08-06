({
	setColumns : function(component) {
        var columns = [
            {label: $A.get('$Label.c.prequest_product_code'), fieldName: 'ProductCodeFormula__c', type: 'text'},
            {label: $A.get('$Label.c.prequest_product_name'), fieldName: 'ProductNameFormula__c', type: 'text'},
            {label: $A.get('$Label.c.dict_quantity'), fieldName: 'Quantity__c', type: 'text'},
            {label: $A.get('$Label.c.prequest_factory_price'), fieldName: 'Price__c', type: 'currency'},
            {label: $A.get('$Label.c.prequest_price_needed'), fieldName: 'PriceNeeded__c', type: 'text'},
            {label: $A.get('$Label.c.prequest_approved_price'), fieldName: 'ApprovedPrice__c', type: 'text'}
        	];
        if (component.get("v.approverMode") == true) {
            columns.push({label: $A.get('$Label.c.dict_submit'), fieldName: 'SubmittedDate__c', type: 'text'});
            columns.push({label: $A.get('$Label.c.dict_reviewed'), fieldName: 'Reviewed__c', type: 'text'});
        }
        columns.push({label: $A.get('$Label.c.dict_status'), fieldName: 'Status__c', type: 'text'});
        component.set('v.columns', columns);
    },
    /* Sends the event to the parent to reload the info of this component */
    emitReloadList : function(component) {
        var cmpEvent = component.getEvent("reloadList"); 
        cmpEvent.setParams({"reload" : true}); 
        cmpEvent.fire();
    },
    /* Sends the event to the parent to inform that something has changed on the items */
    emitChangedList : function(component) {
        var cmpEvent = component.getEvent("onChange"); 
        cmpEvent.fire();
    }
})