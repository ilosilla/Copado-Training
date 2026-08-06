({
	init : function(component, event, helper) {
        var inputVariables = [
            {                
                name : 'recordId',
                type : 'String',
                value: component.get("v.recordId")
            }
        ];
        var flow = component.find("flowData");
        flow.startFlow("Installation_Request_State", inputVariables);		
	} // init    
})