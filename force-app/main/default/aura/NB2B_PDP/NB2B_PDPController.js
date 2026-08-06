({
	doInit : function(component, event, helper) {
		//var recordId = component.get('v.recordId');
        var action = component.get("c.checkShowButton");
        action.setParams({
            recordId : component.get("v.recordId"),
            url		 : null
        });            
        //action.setCallback(this, response => this.showButton(component, response));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var wrapper = response.getReturnValue();
            if (state === "SUCCESS" && wrapper != null && wrapper.isCorrect) {
                try {
                component.set('v.showButton', wrapper.showButton);
                component.set('v.product'	, wrapper.product);
                component.set('v.price'		, wrapper.price);                
                component.set('v.showUMV'	, true);
                component.set('v.webStoreId', wrapper.webStoreId);
                component.set('v.unitProductPrice', wrapper.productUnit);
                component.set('v.unitProductPricePlural', wrapper.productUnitPlural);
                component.set('v.unitPrice', wrapper.priceUnit);
                    //console.log('NB2B_PDPController - doInit() - wrapper.urlImageList:', wrapper.urlImageList);
                    if(wrapper.urlImageList.length == 0){
                        //console.log('NB2B_PDPController - doInit() - NOT isEmpty
                        wrapper.urlImageList.push($A.get('$Resource.NB2B_productDefaultImage'));
                        //wrapper.urlImageList.forEach(imgUrl => helper.checkImageAvailability(imgUrl));
                        console.log('NB2B_PDPController - doInit() - wrapper.urlImageList:', wrapper.urlImageList);
                    }
                    //console.log('NB2B_PDPController - doInit() - FINISHED CHECKING!!');
                component.set('v.urlImageList', wrapper.urlImageList);
                component.set('v.showForm', true);
                    component.set('v.hasActivePBEntry', (wrapper.price && wrapper.price.IsActive));
                component.set('v.cartId', wrapper.cartId);

                if(wrapper.language != null){
                    component.set('v.userLanguage', wrapper.language.replace("_", "-"));
                }else{
                    component.set('v.userLanguage', 'en-US');
                }
                if(wrapper.product.UmbMt2__c == null || wrapper.product.UmbMt2__c == 0){
                    component.set('v.showButtonCmp'	, false);
                }else{
                    //calculamos el precio por M2
                    var price = wrapper.price;
                    var product = wrapper.product;
                    //CALCULAMOS EL PRECIO POR UNIDAD
                    if(price.Uprice__c == product.Umv__c){
                            //SET SALES PRICE
                            component.set('v.salesPrice', price.UnitPrice.toLocaleString(component.get('v.userLanguage')));
                            //SET ORIGINAL PRICE OR REAL UNIT PRICE.
                            if(price.UMVPrice__c != null){
                                component.set('v.originalPrice', price.UMVPrice__c.toLocaleString(component.get('v.userLanguage')));
                                component.set('v.originalUnit', wrapper.originalProductUnit);
                            }else{
                                component.set('v.originalPrice', price.UnitPrice.toLocaleString(component.get('v.userLanguage')));
                                component.set('v.originalUnit', wrapper.priceUnit);
                            }
                            component.set('v.salesPrice',price.UnitPrice.toLocaleString(component.get('v.userLanguage')));
                        }else{
                            //SET ORIGINAL PRICE OR REAL UNIT PRICE.
                            component.set('v.originalPrice', price.UnitPrice);
                            component.set('v.originalUnit', wrapper.priceUnit);
                        
                            let calculatedPrice = price.UnitPrice;
                            if(product.Umv__c == 'BOX' || product.Umv__c == 'CJ' || product.Umv__c == 'CV'){
                            if(price.Uprice__c == 'PZS' || price.Uprice__c == 'UN'){
                                    calculatedPrice = Math.floor(price.UnitPrice * product.PcsXBox__c * 100)/100;
                                }else if(price.Uprice__c == 'MT2' || price.Uprice__c == 'M2'){
                                    calculatedPrice = Math.floor(price.UnitPrice * (Math.floor(product.M2XBox__c * 1000)/1000) * 100)/100;
                            }else{
                                    calculatedPrice = Math.floor(price.UnitPrice * 100)/100;
                            }                                
                        }else if(product.Umv__c == 'PZS' || product.Umv__c == 'UN'){
                            if(price.Uprice__c == 'BOX' || price.Uprice__c == 'CJ' || price.Uprice__c == 'CV'){
                                    calculatedPrice = Math.floor(price.UnitPrice / product.PcsXBox__c * 100)/100;
                                }else if(price.Uprice__c == 'MT2' || price.Uprice__c == 'M2'){
                                    calculatedPrice = Math.floor(price.UnitPrice * (Math.floor(product.M2XBox__c * 1000)/1000) / product.PcsXBox__c * 100)/100;
                            }else{
                                    calculatedPrice = Math.floor(price.UnitPrice * 100)/100
                            }                                 
                    }
                            component.set('v.price.UnitPrice',calculatedPrice);
                            component.set('v.salesPrice',price.UnitPrice.toLocaleString(component.get('v.userLanguage')));
                        }
                        component.set('v.showOriginalPrice',(
                            component.get('v.salesPrice') != component.get('v.originalPrice') && 
                            component.get('v.unitProductPrice') != component.get('v.originalUnit')
                        ));
                    }
                } catch (error) {
                    console.error(error);
                }
            }else{
                component.set('v.showButton', false);
            } 
        });
        $A.enqueueAction(action);     
	},
    showCalculator : function(component, event, helper) {
		component.set('v.showComponent', true);
	},
    
    calculateTotals : function(component, event, helper) {
        var total = Number(component.get('v.total'));
        // console.log("total: "+total);

        if(isNaN(total) || total < 0){
            component.set("v.total",component.get('v.totalAux'));
            return;
        }else{
            component.set("v.total",Math.round(total,0));
            component.set("v.totalAux",Math.round(total,0));
            if(!component.get('v.showComponent') && component.get("v.showButtonCmp")){
                helper.calculateTotalsV4(component, event, helper);            
            }else{
                helper.calculateTotals(component, event, helper);            
            }   
        }
	},
    
    createCartItem : function(component, event, helper) {
        var action = component.get('c.sendToCart');
        component.set('v.showSpinner', true);
        if(component.get('v.total') > 0){
            action.setParams({
                recordId : component.get('v.recordId'),
                webStoreId : component.get('v.webStoreId'),
                quantity  :  component.get('v.total'),
                priceBookId : component.get('v.price').Id,
                salesOrg : window.sessionStorage.getItem('salesOrgId'),
                amount : component.get('v.amount'),
                shade : component.get('v.shade')
            });            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //EHG mostrar error si lo hay
                    if(response.getReturnValue() != 'OK'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": response.getReturnValue()
                        });
                        component.set('v.showSpinner', false);
                        toastEvent.fire();
                    }else{
                        //MOSTRAR LA OTRA VENTANA DE CONFIRMACIÓN
                        component.set('v.notPurchased', false);
                        //window.alert('Añadido al carrito');
                        //this.dispatchEvent(new CustomEvent('cartChanged'));
                        var newEvent = new CustomEvent("cartchanged", {
                            bubbles: true,
                            composed: true
                        });
                        component.set('v.showSpinner', false);
                        newEvent.fire();
                        /*this.dispatchEvent(new CustomEvent("cartchanged", {
                            bubbles: true,
                            composed: true
                        }));*/
                    }
                    
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "There was an error in the insertion"
                    });
                    component.set('v.showSpinner', false);
                    toastEvent.fire();
                    
                } 
            });
            $A.enqueueAction(action);     
        }else{
        	var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "No items to add to cart"
                    });
                    toastEvent.fire();
            		component.set('v.showSpinner', false);
        }
	},
	viewCart : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL"); 
                    urlEvent.setParams({
                        "url": '/cart/'+ component.get('v.cartId')
                    });
                    urlEvent.fire();
	},
    moreTotal : function(component, event, helper) {
        var total = component.get('v.total');
        var tot = new Number(total)+1;
		component.set('v.total', tot);
	},

    lessTotal : function(component, event, helper) {
        var total = component.get('v.total');
        var tot = new Number(total)-1;
        if(tot < 0){
            tot = 0;
        }
		component.set('v.total', tot);
	},
    profileUrl: function(component) {
        var profUrl = $A.get('$Resource.yourGraphics') + '/images/avatar1.jpg';
        alert("Profile URL: " + profUrl);
	}

    
})