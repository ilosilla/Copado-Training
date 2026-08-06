({
    calculateTotals : function(component, event, helper) {
		var pieces 	= component.get('v.pieces');
        var boxes 	= component.get('v.boxes');
        var squareM = Number(component.get('v.squareM'));
        var product = component.get('v.product');
        var total   = component.get('v.total');
        var price 	= component.get('v.price');
        var totalPieces 		  = 0;
        var piecesPerArea         = 0;
        var piecesPerAreaReminder = 0;
        var totalArea 		      = 0;
        var pieceMts  			  = 0;
        var pieceMtsReminder 	  = 0;
        var piecesRemainder 	  = 0;

        if(product.PcsXBox__c != null && product.M2XBox__c != null && price.Uprice__c != null){
            //ADD FROM BOXES
            total = boxes;

            pieceMts = product.M2XBox__c/product.PcsXBox__c;

            //CALCULATE PIECES FROM AREA
            piecesPerArea 			= Math.floor(squareM/pieceMts);
            piecesPerAreaReminder 	= (squareM * 100) % (pieceMts * 100)/100;

            if(piecesPerAreaReminder > 0){
               piecesPerArea++; 
            }
            totalPieces = pieces + piecesPerArea;

            //CALCULATE BOXES FROM PIECES
            if(totalPieces > 0){
                if(totalPieces >= product.PcsXBox__c){
                    total 			= total + Math.floor(totalPieces/product.PcsXBox__c);
                    piecesRemainder = totalPieces % product.PcsXBox__c;

                    if(piecesRemainder > 0){
                        total++;
                    }
                }else{
                    total++;
                }
            }

            total * product.M2XBox__c;
            component.set('v.total' , total);
            totalArea = Math.round((totalArea + Number.EPSILON) * 100) / 100;
            component.set('v.squareMTotal', totalArea);

            if(product.BoxXPal__c != null){
                helper.calculatePallets(component, product.BoxXPal__c, total);
            }
        }
	},
    calculateTotalsV2 : function(component, event, helper) {
		var pieces 	= component.get('v.pieces');
        var boxes 	= component.get('v.boxes');
        var squareM = Number(component.get('v.squareM'));
        var pallet = component.get('v.pallet');
        var product = component.get('v.product');
        var price 	= component.get('v.price');
        var total   			  = 0;
        var totalPieces 		  = 0;
        var piecesPerArea         = 0;
        var piecesPerAreaReminder = 0;
        var totalArea 		      = 0;
        var pieceMts  			  = 0;
        var pieceMtsReminder 	  = 0;
        var piecesRemainder 	  = 0;
        var UmbPal;

        if(product.PcsXBox__c != null && product.M2XBox__c != null){
            pieceMts = product.M2XBox__c/product.PcsXBox__c;
            UmbPal = product.BoxXPal__c != null ?  product.BoxXPal__c : 0;
            pieces += pallet * product.PcsXBox__c * UmbPal;
            if(price.Uprice__c == 'UN' || price.Uprice__c == 'PZS' || price.Uprice__c == 'BID' || price.Uprice__c == null){
                total += pieces;
                //CALCULATE PIECES FROM BOXES
                total += boxes * product.PcsXBox__c;

                //CALCULATE PIECES FROM AREA
                piecesPerArea 			= Math.floor(squareM/pieceMts);
                piecesPerAreaReminder 	= (squareM * 100) % (pieceMts * 100)/100;

                if(piecesPerAreaReminder > 0){
                   piecesPerArea++; 
                }
                total += piecesPerArea;
            }else if(price.Uprice__c == 'CJ' || price.Uprice__c == 'SAC' || price.Uprice__c == 'BOX'){
                total += boxes;

                //CALCULATE BOXES FROM AREA
                piecesPerArea 			= Math.floor(squareM/pieceMts);  
                piecesPerAreaReminder 	= (squareM * 100) % (pieceMts * 100)/100;

                if(piecesPerAreaReminder > 0){
                   piecesPerArea++; 
                }
                pieces += piecesPerArea;
                //CALCULATE BOXES FROM PIECES
                if(pieces > 0){
                    if(pieces >= product.PcsXBox__c){
                    	total += Math.trunc(pieces / product.PcsXBox__c);
                        if(pieces % product.PcsXBox__c > 0){
                            total++;
                        }
                    }else{
                        total++;
                    }
                }
            }else if(price.Uprice__c == 'MT2'){
                //CALCULATE MT2 FROM PIECES AND BOXES
                UmbPal = product.BoxXPal__c != null ?  product.BoxXPal__c : 0;

                var piecesTotal = pieces + (boxes * product.PcsXBox__c);
                piecesPerArea = piecesTotal * pieceMts;
                //piecesPerArea = pieceMts * piecesPerArea;
                piecesPerArea += squareM;
                total += Math.trunc( piecesPerArea );
                if(piecesPerArea % 1 > 0){
                    total ++;
                }
            }
            component.set('v.total' , total);
            component.set('v.amount', (total * price.UnitPrice).toFixed(2));
            totalArea = Math.round((totalArea + Number.EPSILON) * 100) / 100;
            component.set('v.squareMTotal', totalArea);
        }
	},

    calculateTotalsV3 : function(component, event, helper) {
		var pieces 	= Number(component.get('v.pieces'));
        var boxes 	= Number(component.get('v.boxes'));
        var squareM = Number(component.get('v.squareM'));
        var pallet = Number(component.get('v.pallet'));

        //VALIDATE FIELD TYPES
        if(pieces == 'NaN'){
            window.alert('pieces');
        }
        if(boxes == 'NaN'){
            window.alert('boxes');
        }
        if(squareM == 'NaN'){
            window.alert('squareM');
        }
        if(pallet == 'NaN'){
            window.alert('pallet');
        }

        var product = component.get('v.product');
        var price 	= component.get('v.price');
        var total   			  = 0;
        var totalPieces 		  = 0;
        var piecesPerArea         = 0;
        var piecesPerAreaReminder = 0;
        var totalArea 		      = 0;
        var pieceMts  			  = 0;
        var pieceMtsReminder 	  = 0;
        var piecesRemainder 	  = 0;
        var UmbPal;
        var priceMt2 = 0;
        var reminder =0;

        //CALCULATE PIECES
        if(product.PcsXBox__c != null && product.M2XBox__c != null && price.Uprice__c != null){
        	pieceMts = product.M2XBox__c/product.PcsXBox__c;
            UmbPal = product.BoxXPal__c != null ?  product.BoxXPal__c : 0;
            boxes += pallet * product.BoxXPal__c;
            piecesPerArea 			= Math.floor(squareM/pieceMts);
            piecesPerAreaReminder 	= (squareM * 100) % (pieceMts * 100)/100;

            if(piecesPerAreaReminder > 0){
                piecesPerArea++;
            }
            var piecesTotal = pieces + (boxes * product.PcsXBox__c) + (piecesPerArea);
            var boxesTotal = 0;
            var areaTotal =(piecesTotal * pieceMts);
            boxesTotal = Math.floor(piecesTotal/product.PcsXBox__c); 
            reminder = (piecesTotal * 100) % (product.PcsXBox__c * 100)/100;
            if(reminder > 0){
                boxesTotal++; 
            }
            //pieces += pallet * product.PcsXBox__c * UmbPal;
            if(product.Umv__c == 'MT2'){
                //MT2 ES UNA PIEZA  = pieceMts
                //
                //MT2 ES UNA CAJA  = pieceMts * product.PcsXBox__c
                //
                //MT2 ES UNA CAJA  = pieceMts * product.PcsXBox__c * product.BoxXPal__c

                //CALCULATE ALL MT2 FROM ALL SELECTED

                //CON EL AREA, MIRAMOS CUANTO PRODUCTO SE HA SELECCIONADO
				//SI SON PIEZAS, UNIDADES
                reminder = 0;
                priceMt2 = areaTotal * price.UnitPrice;

                if(product.Umv__c == 'CJ' || product.Umv__c == 'BOX'){
                    areaTotal = boxesTotal * product.M2XBox__c;
                    component.set('v.total' , boxesTotal);
                    priceMt2 = areaTotal * price.UnitPrice;
                }else{
                    component.set('v.total' , piecesTotal);
                }
                //component.set('v.amount', (priceMt2).toFixed(2));
                //component.set('v.amountTxt', (Math.floor(priceMt2 * 100)/100).toLocaleString(component.get('v.userLanguage')));
                component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                if(product.BoxXPal__c != null){
                    //helper.calculatePallets(component, product.BoxXPal__c, total);
                }
            } else if(product.Umv__c == 'BOX' || product.Umv__c == 'CJ' || product.Umv__c == 'CV'){
                //CALCULATE PIECES TOTAL
                component.set('v.total' , boxesTotal);
				areaTotal = boxesTotal * product.M2XBox__c;
                component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                //component.set('v.amount', (boxesTotal * price.UnitPrice).toFixed(2));
                //component.set('v.amountTxt', (Math.floor(boxesTotal * price.UnitPrice * 100)/100).toLocaleString(component.get('v.userLanguage')));
            } else if(product.Umv__c == 'PZS' || product.Umv__c == 'UN'){
                component.set('v.total' , piecesTotal);
                areaTotal = piecesTotal / product.PcsXBox__c * (product.M2XBox__c);
                component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                //component.set('v.amount', (piecesTotal * price.UnitPrice).toFixed(2));
                component.set('v.amountTxt', (Math.floor(piecesTotal * price.UnitPrice * 100)/100).toLocaleString(component.get('v.userLanguage')));
            }
        }
	},
    calculatePallets : function(component, boxesPerPallet, boxes) {
        if(boxesPerPallet != null){
            if(boxes >= boxesPerPallet){
                //HAY SUFICIENTES CAJAS PARA RELLENAR AL MENOS UN PALLET, VAMOS A CALCULAR CUANTOS
                var pallets = Math.floor(boxes/boxesPerPallet);
                //HAY QUE VER SI QUIEREN EL RESTO QUE SOBRE DEL PALLET O SOLO NUMEROS ENTEROS
                var remainder = boxes % boxesPerPallet;
                component.set('v.pallet', pallets);
            }else{
                //NO HAY SUFICIENTES CAJAS PARA RELLENAR UN PALLET
                component.set('v.pallet', 0);
            }
        }
	}
})