({
    init : function(component, event, helper) {
        var docType = component.get("v.docType");
        var label = helper.getLabel(docType);
        component.set("v.docLabel", label);
                
        component.set('v.validate', function(event) {

            var userInput = component.get('v.docNumber');
			var required = component.get('v.required');            
            
            if (!userInput && required) {
				return { isValid: false, errorMessage: 'A value is required' };                
            }
                      
         	if (isNaN(userInput)) {
            	return { isValid: false, errorMessage: 'Please enter a valid number' };                
        	}
        
        	if (userInput && (userInput.length < 8 || userInput.length > 10)) {
				return { isValid: false, errorMessage: 'SAP document numbers should have between 8 and 10 digits' };                
            }
			return { isValid: true };        
        }); // validate
	} // init
})