({
	doInit : function(component, event, helper) {
		console.log("Tabla360Component");
        
        console.log(JSON.stringify(component.get("v.tableSource")));
        
        let tableSource = [
                        {
                            "vbeIn": "0006001111",
                            "audat": 20181024,
                            "bstnk": "RECL KEY TEST",
                            "netwr": 186,
                            "mwsbp": 37.2,
                            "total": 223.2,
                            "vbtyp": "C",
                            "auart": "ZW04",
                            "kunnr": "0001085769",
                            "name1": "CLIENT FOR DUNNING TESTING",
                            "bukrs_vf": "502"
                        },
                        {
                            "vbeIn": "0006001275",
                            "audat": 20181218,
                            "bstnk": "PROOF OF ADVANCES",
                            "netwr": 7098,
                            "mwsbp": 1419.6,
                            "total": 8517.6,
                            "vbtyp": "C",
                            "auart": "ZW04",
                            "kunnr": "0001085769",
                            "name1": "CLIENT FOR DUNNING TESTING",
                            "bukrs_vf": "502"
                        }            
                    ];
        
        for(let i=0; i<tableSource.length; i++){
            
            let audat = tableSource[i].audat.toString();
            
            if(audat.length == 8){
                tableSource[i].audat = audat.substring(0, 4) + '/' + audat.substring(4, 6) +'/' + audat.substring(6, 8);
            
            }
        }
        
        component.set("v.tableSource", tableSource);
       
	},
    
    handleOnCancel : function(component, event, helper) {
        component.set("v.mostrar", false);
    }
})