({
	calculateTotals : function(component,event,helper) {
		var price = component.get('v.price');
		var product = component.get('v.product');
        var quantity = component.get('v.quantity');     
		var pricePerProduct;

		if(price.Uprice__c == 'KG'){
			pricePerProduct = quantity * product.UmbKg__c * price.UnitPrice;
			component.set('v.priceTotal', (pricePerProduct).toFixed(2));
			component.set('v.priceTotalTxt', (Math.floor(pricePerProduct * 100)/100).toLocaleString(component.get('v.userLanguage')));
		}else{
			component.set('v.priceTotal', (quantity * price.UnitPrice).toFixed(2));
            component.set('v.priceTotalTxt', (Math.floor(quantity * price.UnitPrice * 100)/100).toLocaleString(component.get('v.userLanguage')));
		}
	}
})