({
    init : function(component, event, helper) {
        helper.setColumns(component);
    },
    /* Sends the event to the parent that an Item has been selected to be edited */
    emitEditItem : function(component, event, helper) {
        var selectedItem = event.getSource().get("v.value");
        var cmpEvent = component.getEvent("editItem");
        cmpEvent.setParams({"itemIndex" : selectedItem});
        cmpEvent.fire();
    },
    /* Not used right now. It Marks all items as "to approval" */
	selectAll: function(component, event, helper) {
        var selectedHeaderCheck = event.getSource().get("v.value");
        var listOfAllItems = component.get("v.items");
        var approverMode = component.get("v.approverMode");
        for (var i = 0; i < listOfAllItems.length; i++) {

            if (approverMode == true) {
                listOfAllItems[i].isChecked = selectedHeaderCheck;
            } else {
                if (selectedHeaderCheck == true && (listOfAllItems[i].Status__c == null || listOfAllItems[i].Status__c == 'NOTSENT')) {
                    listOfAllItems[i].isChecked = true;
                } else {
                    listOfAllItems[i].isChecked = false;
                }
            }

        }
        component.set("v.items", listOfAllItems);
        helper.emitChangedList(component);
    },
    /* Marks an item "to approval" */
    checkboxSelect: function(component, event, helper) {
        helper.emitChangedList(component);
    },
    /* Marks an item as "Approved" */
    checkboxSelectApproved: function(component, event, helper) {
        var modifiedIndex = event.getSource().get("v.text");
        var listOfAllItems = component.get("v.items");
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (i == modifiedIndex) {
                listOfAllItems[i].isCheckedReject = false;
            }
        }
        component.set("v.items", listOfAllItems);
        helper.emitChangedList(component);
    },
    /* Marks an item as "Rejected" */
    checkboxSelectRejected: function(component, event, helper) {
        var modifiedIndex = event.getSource().get("v.text");
        var listOfAllItems = component.get("v.items");
        for (var i = 0; i < listOfAllItems.length; i++) {
            if (i == modifiedIndex) {
                listOfAllItems[i].isCheckedApprove = false;
                 listOfAllItems[i].ApprovedPrice__c = null;
            }
        }
        component.set("v.items", listOfAllItems);
        helper.emitChangedList(component);
    },
})