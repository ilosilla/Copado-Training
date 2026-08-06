({
	addToCart : function(component, event, helper) {
        try{
            component.set('v.showComponent', false);
            //component.get('v.product');
            var total = component.get('v.total');
            //var totalAux = component.get('v.totalAux');
            component.set('v.totalAux', total);
        }catch(error){console.error(e);}
	},
    handleCancel: function(component,event,helper){
        try{
            component.set('v.showComponent',false);
        }catch(e){ console.error(e); }
    },

    upPieces : function(component, event, helper) {
        try{
            var pieces = Number(component.get('v.pieces'));
            pieces = pieces + 1;
            component.set('v.pieces', pieces);
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    downPieces : function(component, event, helper) {
        try{
            var pieces = Number(component.get('v.pieces'));
            if(pieces > 0){
                pieces = pieces - 1;
            }
            component.set('v.pieces',pieces);
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    upBoxes : function(component, event, helper) {
        try{
            var boxes = Number(component.get('v.boxes'));
            boxes = boxes + 1;
            component.set('v.boxes', boxes);
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    downBoxes : function(component, event, helper) {
        try{
            var boxes = Number(component.get('v.boxes'));
            if(boxes > 0){
                boxes = boxes - 1;
            }
            component.set('v.boxes', boxes);
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    upPallet : function(component, event, helper) {
        try{
            var pallet = Number(component.get('v.pallet'));
            pallet = pallet + 1;
            component.set('v.pallet', pallet);
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    downPallet : function(component, event, helper) {
        try{
            var pallet = Number(component.get('v.pallet'));
            if(pallet > 0){
                pallet = pallet - 1;
            }
            component.set('v.pallet', pallet);
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    calculateMts : function(component, event, helper) {
        try{
            var squareM = Number(component.get('v.squareM'));
            console.log(String(component.get('v.boxes')));
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    calculateMtsRound : function(component, event, helper) {
        try{
		    var squareM = component.get('v.squareM');
            helper.calculateTotalsV3(component, event, helper);
        }catch(e){console.error(e);}
	},

    createCartItem : function(component, event, helper) {
        try{
            var action = component.get('c.sendToCart');
            action.setParams({
                recordId : component.get('v.recordId'),
                webStoreId : component.get('v.webStoreId'),
                quantity  :  component.get('v.total'),
                priceBookId : component.get('v.price').Id,
                salesOrg : window.sessionStorage.getItem('salesOrgCode'),
                amount : component.get('v.amount'),
                shade : component.get('v.shade')
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.showComponent', false);
                    $A.get('e.force:refreshView').fire();
                    //location.reload();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "There was an error in the insertion"
                    });
                    toastEvent.fire();
                } 
            });
            $A.enqueueAction(action);
        }catch(e){console.error(e);}
	}
})