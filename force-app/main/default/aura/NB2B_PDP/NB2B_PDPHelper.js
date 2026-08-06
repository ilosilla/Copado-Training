({
	calculateTotalsV3 : function(component, event, helper) {
		var pieces 	= 0;
        var boxes 	= 0;
        var squareM = 0;
        var pallet = 0;
        var product = component.get('v.product');
        var price 	= component.get('v.price');
        var total   			  = Number(component.get('v.total'));
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
            if(product.Umv__c == 'CJ' || product.Umv__c == 'BOX' || product.Umv__c == 'CV'){
                boxes = total;
            }else{
                pieces = total;
            }
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
            if(price.Uprice__c == 'MT2'){
                //MT2 ES UNA PIEZA  = pieceMts
                //
                //MT2 ES UNA CAJA  = pieceMts * product.PcsXBox__c
                //
                //MT2 ES UNA CAJA  = pieceMts * product.PcsXBox__c * product.BoxXPal__c
                
                //CALCULATE ALL MT2 FROM ALL SELECTED
                
                
                //CON EL AREA, MIRAMOS CUANTO PRODUCTO SE HA SELECCIONADO
				//SI SON PIEZAS, UNIDADES
                reminder = 0;
                priceMt2 = (Math.floor(areaTotal * 1000)/1000) * price.UnitPrice;
                    
                if(product.Umv__c == 'CJ' || product.Umv__c == 'BOX' || product.Umv__c == 'CV'){
                    
                    areaTotal = boxesTotal * product.M2XBox__c;
                    //component.set('v.total' , boxesTotal);
                    priceMt2 = (Math.floor(areaTotal * 1000)/1000) * price.UnitPrice;
                    component.set('v.weight', (Math.floor(total * product.UmbKg__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
                }else{
                    //component.set('v.total' , piecesTotal);
                    component.set('v.weight', (Math.floor(total * product.UmbKg__c / product.PcsXBox__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
                }
                component.set('v.amount', (priceMt2).toFixed(2));
                component.set('v.amountTxt', (priceMt2).toFixed(2).toLocaleString(component.get('v.userLanguage')));
                component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                
                if(product.BoxXPal__c != null){
                    //helper.calculatePallets(component, product.BoxXPal__c, total);
                }
            } else if(price.Uprice__c == 'BOX' || price.Uprice__c == 'CJ' || price.Uprice__c == 'CV'){
                //CALCULATE PIECES TOTAL
                if(product.Umv__c == 'PZS' || product.Umv__c == 'UN'){
                    areaTotal = (total * product.M2XBox__c / product.PcsXBox__c);
                    component.set('v.amount', (total * price.UnitPrice / product.PcsXBox__c).toFixed(2));
                    component.set('v.amountTxt', (total * price.UnitPrice / product.PcsXBox__c).toFixed(2).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.weight', (Math.floor(total * product.UmbKg__c / product.PcsXBox__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
                }else{
					areaTotal = total * product.M2XBox__c;
                    component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.amount', (boxesTotal * price.UnitPrice).toFixed(2));
                    component.set('v.amountTxt', (boxesTotal * price.UnitPrice).toFixed(2).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.weight', (Math.floor(total * product.UmbKg__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
                }
            } else if(price.Uprice__c == 'PZS' || price.Uprice__c == 'UN'){
                //component.set('v.total' , piecesTotal);
                if(product.Umv__c == 'PZS' || product.Umv__c == 'UN'){
                    areaTotal = total *(product.M2XBox__c) / product.PcsXBox__c;
                    component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.amount', (total * price.UnitPrice).toFixed(2));
                    component.set('v.amountTxt', (total * price.UnitPrice).toFixed(2).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.total', Number(piecesTotal));
                    component.set('v.weight', (Math.floor(total * product.UmbKg__c / product.PcsXBox__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
                }else{
                    areaTotal = total *(product.M2XBox__c);
                    component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.amount', (total * price.UnitPrice * product.PcsXBox__c).toFixed(2));
                    component.set('v.amountTxt', (total * price.UnitPrice * product.PcsXBox__c).toFixed(2).toLocaleString(component.get('v.userLanguage')));
                    component.set('v.total', Number(total));
                    component.set('v.weight', (Math.floor(total * product.UmbKg__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
                }
            }
        }
        //component.set('v.weight', (Math.floor(total * product.UmbKg__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
	},
    calculateTotalsV4 : function(component, event, helper) {
		var pieces 	= 0;
        var boxes 	= 0;
        var squareM = 0;
        var pallet = 0;
        var product = component.get('v.product');
        var price 	= component.get('v.price');
        var total   = Number(component.get('v.total'));
        var areaTotal;
        //CALCULATE PRICES
        if(product.Umv__c == 'CJ' || product.Umv__c == 'BOX' || product.Umv__c == 'CV'){
            areaTotal = total * product.M2XBox__c;
            component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage'))); 
            //priceMt2 = (Math.floor(areaTotal * 1000)/1000) * price.UnitPrice;
            //component.set('v.weight', (Math.floor(total * product.UmbKg__c * 100)/100).toLocaleString(component.get('v.userLanguage')));   
        }else{
            areaTotal = total * product.PcsXBox__c * product.M2XBox__c;
            component.set('v.squareMTotal', (Math.floor(areaTotal * 100) / 100.0).toLocaleString(component.get('v.userLanguage'))); 
            //component.set('v.weight', (Math.floor(total * product.UmbKg__c / product.PcsXBox__c * 100)/100).toLocaleString(component.get('v.userLanguage')));
        }
        component.set('v.weight', (product.PesoUMV__c)? (Math.floor(total * product.PesoUMV__c).toLocaleString(component.get('v.userLanguage'))) : 0);
        component.set('v.amount', (total * price.UnitPrice).toFixed(2));
		component.set('v.amountTxt', (total * price.UnitPrice).toFixed(2).toLocaleString(component.get('v.userLanguage')));
	},
	calculateTotals : function(component,event,helper) {
		var price = component.get('v.price');
		var product = component.get('v.product');
        var quantity = component.get('v.total');     
		var pricePerProduct;

        pricePerProduct = quantity * price.UnitPrice;
        component.set('v.amount', (pricePerProduct).toFixed(2));
        component.set('v.amountTxt', (pricePerProduct).toFixed(2).toLocaleString(component.get('v.userLanguage')));
        
        component.set('v.weight', (product.PesoUMV__c)? (Math.floor(quantity * product.PesoUMV__c * 100)/100).toLocaleString(component.get('v.userLanguage')) : 0);
	},
	
})