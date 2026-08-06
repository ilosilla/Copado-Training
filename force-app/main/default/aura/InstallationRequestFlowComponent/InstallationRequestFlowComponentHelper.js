({
	buildDefaultName : function(opportunityName) {
		var name = $A.get("$Label.c.ins_name_template");
        name = name.replace("%1", opportunityName);
        return name;        
	},
 	validate : function(component) {            
        var name = component.get("v.installationName");
        var nBathrooms =  component.get("v.numberOfBathrooms");
        var nKitchens =  component.get("v.numberOfKitchens");
        var nOthers =  component.get("v.numberOfOthers");
        var nRooms = nBathrooms + nKitchens + nOthers;
        var installer = component.get("v.installer");
        var isOK = true;
        var errorList = [];
        
        if (!name) {
            isOK = false;
            errorList.push($A.get("$Label.c.ins_name_required"));
        } 
        
        if (!nRooms) {
            isOK = false;
            errorList.push($A.get("$Label.c.ins_baths_required"));            
        }
        
        if(!installer) {
            isOK = false;
            errorList.push("Please select the installer");                        
        }

		component.set("v.errorList", errorList);
        if(!isOK) {
            return { isValid: false, errorMessage: '' };
        } else {
            return { isValid: true };
        }
	},
    
    installersToCombo : function(json) {
        var options = new Array();
        var list = JSON.parse(json);
        for (var i = 0; i< list.length; i++) {
            var option = new Object();
            option.label = list[i].Name;
            option.value = list[i].Id;
            options[i] = option;
        }
        return options;
	}
})