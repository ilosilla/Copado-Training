({
    getPicklistSalesOrg : function(cmp) {
        var action = cmp.get("c.getSalesOrgs");
        
        action.setParams({
            recordId : cmp.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            console.log("serverResponse: " + JSON.stringify(serverResponse));
            
            if(state === "SUCCESS"){
                if( serverResponse[0].hasOwnProperty('ERROR') ){
                    cmp.set("v.hasSapId", false);
                    cmp.set("v.initMessage", serverResponse[0].ERROR );
                } else {
                    cmp.set("v.salesOrgOptions", serverResponse);
                    cmp.set("v.hasSapId", true);
                }
                
                cmp.set("v.spinner", false);
            }            
            else if(state === "INCOMPLETE"){                
                console.log("STATUS INCOMPLETE");                
            }            
                else if(state === "ERROR"){                    
                    var errors = response.getError();
                    console.log(errors);                    
                }            
        }); 
        
        $A.enqueueAction(action);
    },
    
    getTableInformation : function(cmp, salesOrg) {
        
        cmp.set("v.spinner", true);
        
        var action = cmp.get("c.getTableInfo");
        
        action.setParams({
            recordId : cmp.get("v.recordId"),
            salesOrg : salesOrg
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var serverResponse = response.getReturnValue();
            
            if(state === "SUCCESS"){
                
                if(!serverResponse.success){
                     //console.log("serverResponse: " + JSON.stringify(serverResponse.json) );
                    let jsonResponse = this.emptyResponse();
                    cmp.set("v.generalTabInfo", jsonResponse);
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": serverResponse.message == undefined ? 'Unknown error' : serverResponse.message,
                        "mode": 'sticky',
                        "type": 'error'
                    });
                    toastEvent.fire();
                    cmp.set("v.spinner", false);
                    
                } else {
                    //console.log("serverResponse parse: " + JSON.stringify(JSON.parse(serverResponse.json) ));
                    //console.log("serverResponse: " + JSON.stringify(serverResponse.json) );
					
                    let jsonBody = JSON.parse(serverResponse.json);
                    
                    this.formatDates(cmp, "open_orders", jsonBody.details.open_orders);
                    this.formatDates(cmp, "open_deliveries", jsonBody.details.open_deliveries);
                    this.formatDates(cmp, "open_items", jsonBody.details.open_items);
                    cmp.set("v.generalTabInfo", jsonBody);
                    //window.setTimeout(function(){ cmp.set("v.spinner", false); }, 1000);
                    cmp.set("v.spinner", false);
                    
                }
                
            }            
            else if(state === "INCOMPLETE"){                
                console.log("STATUS INCOMPLETE");                
            }            
                else if(state === "ERROR"){                    
                    var errors = response.getError();
                    console.log(errors);                    
                }             
        }); 
        
        $A.enqueueAction(action);
    },
    
    pintarCombobox : function(cmp, salesOrgCmp) {
        let isValid = false;
        
        if(salesOrgCmp == undefined){
            console.log("ERROR salesOrg component not found");
        } else {
            
            if(salesOrgCmp.get("v.value") == undefined){
                $A.util.addClass(salesOrgCmp, 'slds-has-error');
                console.log("User must select a Sales Org");
                
            } else {
                isValid = true;
            }
        }
        
        return isValid;
    },
    
    formatDates : function(cmp, tableName, objects){
        
        switch(tableName) {
                
            case 'open_orders':
                objects.forEach(object => {
                    let audat = object.audat.toString();
                    if(audat.length == 8) object.audat = audat.substring(0, 4) + '/' + audat.substring(4, 6) + '/' + audat.substring(6, 8);
               		
                });
                cmp.set("v.openOrders", objects);
                break;
                
            case 'open_deliveries':
                objects.forEach(object => {
                    let fkdat = object.fkdat.toString();
                   	if(fkdat.length == 8) object.fkdat = fkdat.substring(0, 4) + '/' + fkdat.substring(4, 6) +'/' + fkdat.substring(6, 8);
                });
                cmp.set("v.openDeliveries", objects);
                break;
                
            case 'open_items':
                objects.forEach(object => {
                    let bldat = object.bldat.toString();
                    if(bldat.length == 8) object.bldat = bldat.substring(0, 4) + '/' + bldat.substring(4, 6) +'/' + bldat.substring(6, 8);
                    let fdtag = object.fdtag.toString();
                    if(fdtag.length == 8) object.fdtag = fdtag.substring(0, 4) + '/' + fdtag.substring(4, 6) +'/' + fdtag.substring(6, 8);
                    let budat = object.budat.toString();
                    if(budat.length == 8) object.budat = budat.substring(0, 4) + '/' + budat.substring(4, 6) +'/' + budat.substring(6, 8);
                });
              	cmp.set("v.openItems", objects);
                break;
                
        }
        // Mauri
        /* 
        for(let i=0; i<tableSource.length; i++){
            
            let audat = tableSource[i].audat.toString();
            
            if(audat.length == 8){
                tableSource[i].audat = audat.substring(0, 4) + '/' + audat.substring(4, 6) +'/' + audat.substring(6, 8);
                
            }
        }*/
        
        //component.set("v.tableSource", tableSource);
    },
    
    emptyResponse : function(cmp) {
        return {
            "balance_to_pay": 0,
            "balance_to_refund": 0,
            "company": "",
            "company_name": "",
            "credit_available": 0,
            "credit_insured": 0,
            "credit_limit": 0,
            "currency": "",
            "details": {
                "open_orders": [],
                "open_deliveries": [],
                "open_items": []
            },
            "payment_terms": "",
            "risk_category": "",
            "risk_exposure": 0,
            "risk_name": "",
            "sap_id": "",
            "terms_name": "",
            "timestamp": " ",
            "totals": {
                "open_orders": 0,
                "open_deliveries": 0,
                "closed_deliveries": 0,
                "open_items": 0,
                "overdue_items": 0,
                "deposits": 0,
                "fi_balance": 0
            }
        };
    },
    
/*    
    fakeResponse : function(cmp) {
        return {
            "balance_to_pay": 11672,
            "balance_to_refund": 0,
            "company": "502",
            "company_name": "PORCELANOSA SOUTHEAST LTD",
            "credit_available": -2931.2,
            "credit_insured": 0,
            "credit_limit": 0,
            "currency": "GBP",
            "details": {
                "open_orders": [
                    {
                        "vbeln": "0006001111",
                        "audat": 20181024,
                        "bstnk": "PRUEBA CLAVE RECL",
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
                        "vbeln": "0006001275",
                        "audat": 20181210,
                        "bstnk": "PRUEBA ANTICIPOS",
                        "netwr": 7098,
                        "mwsbp": 1419.6,
                        "total": 8517.6,
                        "vbtyp": "C",
                        "auart": "ZW04",
                        "kunnr": "0001085769",
                        "name1": "CLIENT FOR DUNNING TESTING",
                        "bukrs_vf": "502"
                    }
                ],
                "open_deliveries": [
                    {
                        "kunag": "0001085769",
                        "name1": "CLIENT FOR DUNNING TESTING",
                        "vbeln": "0085000579",
                        "fkdat": 20181024,
                        "impor": 0,
                        "antic": 0,
                        "netwr": 186,
                        "mwsbp": 37.2,
                        "total": 223.2,
                        "lifsk": "FI",
                        "cmgst": ""
                    }
                ],
                "open_items": [
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000047",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181024,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100052",
                        "bldat": 20181024,
                        "fdtag": 20181231,
                        "overdue": true,
                        "vbeln": "6218100052",
                        "impte": 223.2,
                        "ipdte": 200,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000048",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181024,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100053",
                        "bldat": 20181024,
                        "fdtag": 20181029,
                        "overdue": true,
                        "vbeln": "6218100053",
                        "impte": 223.2,
                        "ipdte": 223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000049",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181024,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "9999900006",
                        "bldat": 20181024,
                        "fdtag": 20181029,
                        "overdue": true,
                        "vbeln": "9999900006",
                        "impte": 250,
                        "ipdte": 250,
                        "waers": "GBP",
                        "sgtxt": "DEVOLUCIÓN IVA FACTURA 6218100053",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000051",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181025,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100055",
                        "bldat": 20181025,
                        "fdtag": 20181225,
                        "overdue": true,
                        "vbeln": "6218100055",
                        "impte": 223.2,
                        "ipdte": 223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000052",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181026,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "9999900007",
                        "bldat": 20181024,
                        "fdtag": 20181208,
                        "overdue": true,
                        "vbeln": "9999900007",
                        "impte": 250,
                        "ipdte": 250,
                        "waers": "GBP",
                        "sgtxt": "DEVOLUCIÓN IVA FACTURA 6218100053",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000053",
                        "buzei": "004",
                        "umskz": "",
                        "budat": 20181026,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100056",
                        "bldat": 20181026,
                        "fdtag": 20181208,
                        "overdue": true,
                        "vbeln": "6218100056",
                        "impte": -120,
                        "ipdte": -120,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000053",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181026,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100056",
                        "bldat": 20181026,
                        "fdtag": 20190105,
                        "overdue": true,
                        "vbeln": "6218100056",
                        "impte": 223.2,
                        "ipdte": 223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000055",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181108,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100057",
                        "bldat": 20181108,
                        "fdtag": 20181102,
                        "overdue": true,
                        "vbeln": "6218100057",
                        "impte": 446.4,
                        "ipdte": 446.4,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000056",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181108,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100058",
                        "bldat": 20181108,
                        "fdtag": 20181208,
                        "overdue": true,
                        "vbeln": "6218100058",
                        "impte": 241.2,
                        "ipdte": 241.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000057",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181108,
                        "blart": "DG",
                        "kind": "ABONO",
                        "zuonr": "6218500021",
                        "bldat": 20181108,
                        "fdtag": 20181208,
                        "overdue": true,
                        "vbeln": "6218500021",
                        "impte": -223.2,
                        "ipdte": -223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000058",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181108,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100059",
                        "bldat": 20181108,
                        "fdtag": 20181108,
                        "overdue": true,
                        "vbeln": "6218100059",
                        "impte": 464.4,
                        "ipdte": 464.4,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000059",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181108,
                        "blart": "DG",
                        "kind": "ABONO",
                        "zuonr": "6218500022",
                        "bldat": 20181108,
                        "fdtag": 20181108,
                        "overdue": true,
                        "vbeln": "6218500022",
                        "impte": -446.4,
                        "ipdte": -446.4,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000071",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181121,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100070",
                        "bldat": 20181121,
                        "fdtag": 20181118,
                        "overdue": true,
                        "vbeln": "6218100070",
                        "impte": 446.4,
                        "ipdte": 446.4,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "9114000016",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DV",
                        "kind": "FACT. ANTICIPO",
                        "zuonr": "50220189114000016",
                        "bldat": 20181210,
                        "fdtag": 20181210,
                        "overdue": true,
                        "vbeln": "*114000016",
                        "impte": 60,
                        "ipdte": 60,
                        "waers": "GBP",
                        "sgtxt": "PAGADO EN EFECTIVO",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "1050000019",
                        "buzei": "002",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "ZD",
                        "kind": "COBRO",
                        "zuonr": "50220189114000016",
                        "bldat": 20181210,
                        "fdtag": 20181210,
                        "overdue": true,
                        "vbeln": "*114000016",
                        "impte": -60,
                        "ipdte": -60,
                        "waers": "GBP",
                        "sgtxt": "CONTADO",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000105",
                        "buzei": "005",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100092",
                        "bldat": 20181210,
                        "fdtag": 20190208,
                        "overdue": true,
                        "vbeln": "6218100092",
                        "impte": -60,
                        "ipdte": -60,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000105",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100092",
                        "bldat": 20181210,
                        "fdtag": 20190208,
                        "overdue": true,
                        "vbeln": "6218100092",
                        "impte": 223.2,
                        "ipdte": 223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "9114000017",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DV",
                        "kind": "FACT. ANTICIPO",
                        "zuonr": "50220189114000017",
                        "bldat": 20181210,
                        "fdtag": 20181210,
                        "overdue": true,
                        "vbeln": "*114000017",
                        "impte": 75,
                        "ipdte": 75,
                        "waers": "GBP",
                        "sgtxt": "PAID BY BACS",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "9114500005",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "VD",
                        "kind": "ANUL. ANTICIPO",
                        "zuonr": "50220189114000017",
                        "bldat": 20181210,
                        "fdtag": 20181210,
                        "overdue": true,
                        "vbeln": "*114000017",
                        "impte": -75,
                        "ipdte": -75,
                        "waers": "GBP",
                        "sgtxt": "Transferencia",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "1050000020",
                        "buzei": "002",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "ZD",
                        "kind": "COBRO",
                        "zuonr": "50220189114000018",
                        "bldat": 20181210,
                        "fdtag": 20181210,
                        "overdue": true,
                        "vbeln": "*114000018",
                        "impte": -80,
                        "ipdte": -80,
                        "waers": "GBP",
                        "sgtxt": "TARJETA",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "9114000018",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DV",
                        "kind": "FACT. ANTICIPO",
                        "zuonr": "50220189114000018",
                        "bldat": 20181210,
                        "fdtag": 20181210,
                        "overdue": true,
                        "vbeln": "*114000018",
                        "impte": 80,
                        "ipdte": 80,
                        "waers": "GBP",
                        "sgtxt": "PAGADO CON TARJETA DE CRÉDITO",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000109",
                        "buzei": "005",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100095",
                        "bldat": 20181210,
                        "fdtag": 20190208,
                        "overdue": true,
                        "vbeln": "6218100095",
                        "impte": -80,
                        "ipdte": -80,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2018",
                        "belnr": "4030000109",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20181210,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6218100095",
                        "bldat": 20181210,
                        "fdtag": 20190208,
                        "overdue": true,
                        "vbeln": "6218100095",
                        "impte": 223.2,
                        "ipdte": 223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2019",
                        "belnr": "9114000003",
                        "buzei": "002",
                        "umskz": "T",
                        "budat": 20190416,
                        "blart": "DV",
                        "kind": "ANTICIPO",
                        "zuonr": "50220199114000003",
                        "bldat": 20190416,
                        "fdtag": 20190416,
                        "overdue": false,
                        "vbeln": "*114000003",
                        "impte": -3500,
                        "ipdte": -3276.8,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": true
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2019",
                        "belnr": "9114000003",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20190416,
                        "blart": "DV",
                        "kind": "FACT. ANTICIPO",
                        "zuonr": "50220199114000003",
                        "bldat": 20190416,
                        "fdtag": 20190416,
                        "overdue": false,
                        "vbeln": "*114000003",
                        "impte": 3500,
                        "ipdte": 3500,
                        "waers": "GBP",
                        "sgtxt": "PAGADO CON TRANSFERENCIA",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2019",
                        "belnr": "4030000003",
                        "buzei": "004",
                        "umskz": "",
                        "budat": 20190416,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6215100033",
                        "bldat": 20190416,
                        "fdtag": 20190608,
                        "overdue": false,
                        "vbeln": "6215100033",
                        "impte": -223.2,
                        "ipdte": -223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    },
                    {
                        "bukrs": "502",
                        "gjahr": "2019",
                        "belnr": "4030000003",
                        "buzei": "001",
                        "umskz": "",
                        "budat": 20190416,
                        "blart": "DR",
                        "kind": "FACTURA",
                        "zuonr": "6215100033",
                        "bldat": 20190416,
                        "fdtag": 20190608,
                        "overdue": false,
                        "vbeln": "6215100033",
                        "impte": 223.2,
                        "ipdte": 223.2,
                        "waers": "GBP",
                        "sgtxt": "",
                        "deposit": false
                    }
                ]
            },
            "payment_terms": "CB30",
            "risk_category": "005",
            "risk_exposure": 2931.2,
            "risk_name": "CONTROL POR ANTICIPOS",
            "sap_id": "0001085769",
            "terms_name": "Transf Eur 30 Dias",
            "timestamp": "20190416134913 ",
            "totals": {
                "open_orders": 8740.8,
                "open_deliveries": 0,
                "closed_deliveries": 223.2,
                "open_items": 3500,
                "overdue_items": 2484.8,
                "deposits": -3276.8,
                "fi_balance": 2708
            }
        };
    },
    */
    
})