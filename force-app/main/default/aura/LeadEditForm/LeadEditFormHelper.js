({
    // ********************************************************
    //                   SERVER FUNCTIONS
    // ********************************************************
    getContacts : function(component, accountId) {
        var action = component.get("c.getContacts");
        action.setParams({
            accountId : accountId
        });            
        action.setCallback(this, response => this.getContactsCallback(component, response));
        $A.enqueueAction(action);                    
    }, 

    // ********************************************************
    //                   CALLBACKS
    // ********************************************************
    getContactsCallback : function(component, response) {                
        var state = response.getState();
        var list = response.getReturnValue();                
        var selected = component.get('v.contactId');
        if(state === "SUCCESS") {  
            if (list.length > 0) {
                for (var i = 0; i < list.length; i++)  {
                    list[i].selected = (list[i].Id == selected);
                }
            } else {
                component.set('v.contactId', '');
            }
            component.set('v.contactList', list);
        } 
        component.set('v.loading', false);
    }
})