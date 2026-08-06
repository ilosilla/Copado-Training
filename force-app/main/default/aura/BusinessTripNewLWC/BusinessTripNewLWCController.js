({
  init : function (cmp) {
    var flow = cmp.find("flowData");
    flow.startFlow("New_Trip_Request");
  },

  handleFlowStatusChange : function(component, event, helper) {
        var status = event.getParam("status");
        console.log("Flow status: " + status);

        if (status === "FINISHED") {
            console.log('FINISHED FLOW');
            // Obtener output variable "recordId"
            var outputVariables = event.getParam("outputVariables");
            var recordId;

            if (outputVariables) {
                outputVariables.forEach(function (ov) {
                    if (ov.name === "recordId") {     // nombre EXACTO como está en el Flow
                        recordId = ov.value;
                    }
                });
            }

            // Si existe el recordId, navegar al registro creado
            if (recordId) {
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
            }
        }
    }
  
})