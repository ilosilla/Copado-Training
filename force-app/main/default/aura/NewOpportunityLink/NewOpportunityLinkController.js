({
	init : function(component, event, helper) {  
        Promise.all([
            helper.getButtons(component),
            helper.getUserData(component)
        ]).then(function(results) {
            var buttons = results[0];
            var userData = results[1];
            component.set("v.buttons", buttons);
            component.set("v.currentUser", userData);
            var sizeButtons = buttons.length;
            var firstOption = sizeButtons > 0 ? buttons[0] : null;
            
            if (sizeButtons == 0) {
                helper.showAlert(component);
            /*} else if (sizeButtons == 1) {
                component.set("v.selectedOption", firstOption.internalValue);
                $A.enqueueAction(component.get('c.doByOption'));*/
            } else {
                console.log('OPTIONS: ' + buttons);
                helper.showOptions(component);
                component.set("v.isActive", true);
            }
        });
    },
    
    onSelectOption : function(component, event, helper) {
        var selected = '';
        if (event.currentTarget) {
           selected = event.currentTarget.id.replace('id-', '');
        }
        component.set("v.selectedOption", selected);
        component.set("v.selectedOptionBoolean", true);
    },
    
    doByOption : function(component, event, helper) {
        component.set('v.showSpinner', true);
        var selection = component.get("v.selectedOption");
        switch (selection) {
            case 'TILEPLANNER':
                console.log('--------- Open New Tileplanner');
                helper.openNewTilePlanner(component);
                $A.enqueueAction(component.get('c.closeComponent'));
                break;
            case 'MOODBOARD':
                console.log('--------- Open New Moodboard');
                helper.openNewMoodboard(component);
                
                setTimeout(function(){
					$A.enqueueAction(component.get('c.closeComponent'));
                },1000);
                break;
            case 'COUNTERTOP':
                console.log('--------- Open New Countertop');
                helper.openNewCounterTop(component);
                
                setTimeout(function(){
					$A.enqueueAction(component.get('c.closeComponent'));
                },1000);
                break;
        }
    },
    
    closeComponent : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})