({
    
    doInit : function(cmp, evt, hlpr) {
        alert("Aqui voy");
        hlpr.getRecord(cmp);
        hlpr.getPicklistValuesFromField(cmp, 'satisfactionCombobox', 'Opportunity', 'Satisfaction__c');
        hlpr.getPicklistValuesFromField(cmp, 'notSatisfiedCombobox', 'Opportunity', 'ReasonNoInterest__c');
		
	},
    
    changeComboboxValue : function (cmp, evt, hlpr){
        
        var sourceId = evt.getSource().getLocalId();
        var sourceValue = evt.getSource().get('v.value');
        
        var attributeString = 'v.' + sourceId + 'Selected';

        cmp.set(attributeString, sourceValue);
        
        var x = cmp.get(attributeString);
        console.log(x);
        
    }
    
})