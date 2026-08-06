({
    onInit : function(component, event, helper) {
        helper.readInfo(component);
    }, // onInit

    onLoad : function(component, event, helper) { 
        // var record = event.getParam("recordUi");
        // var fieldNames = Object.keys(record.record.fields); // returns a list of field names on the recordId
        // alert(JSON.stringify(record.record.fields["CreatedDate"]));
    },
    
    onStageChange : function(component, event, helper) {         
        var nextComponent = component.find("nextComponent");        
        if (nextComponent) {
            nextComponent.refresh();
        }
    },    

    onOppTypeClick :  function(component, event, helper) {
        var selected = '';
        if (event.currentTarget) {
           selected = event.currentTarget.id.replace('id-', '');
        }
        component.set("v.selectedType", selected);
    }, // onOppTypeClick

    onEditClick :  function(component, event, helper) {
       component.set("v.showModal", true);
    }, // onEnterClick    

    onDeleteClick :  function(component, event, helper) {
        component.set("v.confirmDelete", true);
     }, // onEnterClick    
 
    onComponentCommandEvent : function(component, event, helper) {
        var infoType = component.get("v.infoType");
        var command = event.getParam("command");
        if (command == 'INSERT') {
            var selectedType = component.get("v.selectedType");
            if (selectedType == 'CUSTOMP') {
                helper.setCustomProjectMode(component, event.getParam("arg"));
            }
            if (selectedType == 'KITCHEN') {
                helper.setKitchenMode(component, event.getParam("arg"));
            }
            if (selectedType == 'FACADE') {
                helper.setFacadeMode(component, event.getParam("arg"));
            }
        } else if (command == 'MODAL-PROMPT') {            
            component.set("v.confirmDelete", false);
            if (event.getParam("arg")) { 
                if (infoType == 'CUSTOMP') {
                    helper.deleteCustomProject(component);
                }
                if (infoType == 'KITCHEN') {
                    helper.deleteKitchen(component);
                }
                if (infoType == 'FACADE') {
                    helper.deleteFacade(component);
                }
            }
        }
    } // onComponentCommandEvent

})