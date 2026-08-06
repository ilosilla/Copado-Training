import { LightningElement, api, track } from 'lwc';
import getProductCodes from '@salesforce/apex/b2B_checkProductStock.getProductsByOrder';
import checkProductStockCallout from '@salesforce/apex/b2B_checkProductStock.checkProductStockCallout';
import deleteUncheckedProducts from '@salesforce/apex/b2B_checkProductStock.deleteOrderItemUncheked';
import validateData from '@salesforce/apex/b2B_checkProductStock.validateData';

import saveOrder from '@salesforce/apex/NB2B_OrderController.saveOrder';
import activeOrder from '@salesforce/apex/b2B_checkProductStock.activateOrder';
import nameLabel from '@salesforce/label/c.NB2B_name';
import quantityLabel from '@salesforce/label/c.NB2B_quantity';
import stockLabel from '@salesforce/label/c.NB2B_Stock';
import returnStockLabel from '@salesforce/label/c.NB2B_returnStock';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class B2B_checkStockComponent extends LightningElement {
    @api recordId;
    @api finish;
    @api hasError = false;
    @track productCodesList;
    @track productStockList;
    @track uncheckedProducts = [];
    @track checkedProducts = [];
    @track validationErrors = false;
    @track errorMsg = '';
    @track hasProductsOutStock = false;
    @track showwating = false;

    get hasProducts() {
        return (this.productStockList?.length > 0);
    }

    labels = {
        nameLabel,
        quantityLabel,
        stockLabel,
        returnStockLabel
    }

    connectedCallback(){
        console.log('0ANTES DEL GETPRODUCTORdERS')
        this.getProductOrders();
    }

    getProductOrders(){
        getProductCodes({orderId : this.recordId})
        .then((result) =>{
            this.productCodesList = result;
            console.log('getProductCodes ' + this.productCodesList);
            if (this.productCodesList.length > 0) {
                console.log('Me voy a ver el stock');
                this.checkStockWS();
            }
        })
        .catch((error) =>{
            console.log('getProductCodes ERROR' + JSON.stringify(error));
        })
    }

    showSpinner(){
        this.showwating = true;
    }

    closeSpinner(){
        this.showwating = false;
    }

    checkStockWS(){
        this.showSpinner();
        checkProductStockCallout({orderId : this.recordId, productCodeList: this.productCodesList})
        .then((result) =>{
            if(!result[0].error){
                let productStockWithIcons = [];
                result.forEach((elem) => {
                    if(elem.availstk !== undefined){
                        elem.showIconAvailable = true;
                    } else {
                        elem.showIconAvailable = false;
                        //Hay un producto fuera de stock. Avisar con el panel
                        this.hasProductsOutStock = true;
                    }
                    productStockWithIcons.push(elem);
                });
            this.productStockList = productStockWithIcons;
            console.log("checkProductStock: "+ JSON.stringify(this.productStockList));
            // this.showToast('Success', 'The stock was retrieved correctly', 'success', 'default');
            }else{
                let error = JSON.parse(result[0].error);
                let errorMessage = 'An error occurred while getting the stock: '+error.message;
                console.log('checkStockWS ERROR: ' + errorMessage);
                this.showToast('ERROR', errorMessage, 'error', 'sticky');
            }

            this.closeSpinner();

        })
        .catch((result) =>{
            console.log('checkStockWS ERROR: ' + JSON.stringify(result));
						if(result != null && result[0] != null && result[0].error != null){
							let error = JSON.parse(result[0].error);
							let errorMessage = 'An error occurred while getting the stock: '+error.message;
							console.log('checkStockWS ERROR: ' + errorMessage);
							this.showToast('ERROR', errorMessage, 'error', 'sticky');
						}else{
							this.showToast('ERROR', 'An unexpected error occurred while getting the stock', 'error', 'sticky');
						}
            this.closeSpinner();
        })
    }

    @api
    save(){
        console.log('ENTRO EN EL SAVE');
		this.showSpinner();
        this.validateDataApex();
    }

    getCheckedProducts(){
        console.log('getCheckedProducts');
        let uncheckedProductsAux = [];
        let checkedProductsAux = [];
        this.checkedProducts = [];
        this.uncheckedProducts = [];
        this.productStockList.forEach(element => {
            if(element.available != true){
                uncheckedProductsAux.push(element.product.substring(9));
            }else{
                checkedProductsAux.push(element.product.substring(9));
            }
        });

        if(checkedProductsAux.length != 0){
            this.checkedProducts = checkedProductsAux;
        }
        if(uncheckedProductsAux.length != 0){
            this.uncheckedProducts = uncheckedProductsAux;
            //this.showToast('Warning', 'Some ítems are out of stock and will be excluded form the order. Please check the availability date and tick the ones you want to include in the order.', 'warning', 'default');
        }else{
            // this.showToast('Success', 'All the ítems are in stock. CLick on “Send Order” to process them.', 'success', 'default');
        }

    }

    refreshCheckedList(e){
        console.log('ENTRO SELECTOR ALL' + JSON.stringify(e));
        console.log('LISTA PRODUCTOS INI:'+JSON.stringify(this.productStockList));
        let id = e.target.dataset.id;
        var productsAuxi = [];
        this.productStockList.forEach(element => {
            if(element.product === id){
                element.available = element.available ? false : true;
                productsAuxi.push(element);
            }else{
                productsAuxi.push(element);
            }

        });
        //Se debe actualizar la lista de productos stock list
        this.productStockList = [];
        this.productStockList = [...productsAuxi];
        console.log('LISTA PRODUCTOS FIN:'+JSON.stringify(this.productStockList));
        this.getCheckedProducts();
        console.log('this.productStockList:'+this.productStockList.length);
        console.log('this.uncheckedProducts:'+this.uncheckedProducts.length);
    }

    sapSynchronize(){
        saveOrder({recordId : this.recordId})
        .then((result) =>{
            this.activateOrder();
        })
        .catch((error) =>{
            console.log('sapSynchronize ERROR' + JSON.stringify(error));
        })
    }

    activateOrder(){
        console.log('VOY A activar el order en el servidor');
        activeOrder({orderId : this.recordId})
        .then((result) =>{
            console.log('result:'+JSON.stringify(result));
						if(result != null){
							if(result === 'OK'){
                                console.log('[RPR] ES OK');                                
									this.showToastAndRefresh('SUCCESS', 'Order activated successfully', 'success', 'default');
                                    console.log('======>2');
									const finish  = true;
                                    console.log('======>3');
									const valueChangeEvent = new CustomEvent("finish", {
											detail: { finish }
									});
                                    console.log('======>4');
									// Fire the custom event
									this.dispatchEvent(valueChangeEvent);
                                    console.log('======>5');
									this.closeSpinner();
                                    console.log('======>6');
							} else {
                                console.log('[RPR] ES ERROR')
									console.log('activateOrder ERROR' + JSON.stringify(result));

									this.showToast('ERROR', result, 'error', 'sticky');
									this.closeSpinner();
							}
						}else{
							this.showToast('ERROR', 'There was a problem creating the order, please contact your administrator.', 'error', 'sticky');
							this.closeSpinner();
						}

        })
        .catch((error) =>{
            console.log('activateOrder ERROR' + JSON.stringify(error));
            console.log('activateOrder ERROR 2' + error);
            this.showToast('ERROR', error, 'error', 'sticky');
            this.closeSpinner();
        })
    }
    showToastAndRefresh(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
        this.dispatchEvent(new CustomEvent('refresh'));
        // $A.get('e.force:refreshView').fire();
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    validateDataApex(){
        this.errorMsg = ''
        validateData({orderId : this.recordId})
        .then((result) =>{
            if(result.length == 0){
                this.processOrder();
            } else {
                this.validationErrors = true;
                console.log("result error: "+result);
                // result.add("The order account and pick up address must be in same Sales Organization.");
                // result.add("The order account and pick up address must be in same Sales Organization.");
                result.forEach(element => {
                    console.log("element error: "+element);
                    // this.errorMsg = this.errorMsg + element;// + ' <br/> ';
                    this.showToast('ERROR', element, 'error', 'default');
                });
                // this.showToast('ERROR', this.errorMsg, 'error', 'sticky');
            }
        })
        .catch((error) =>{
            console.log('validateDataApex ERROR' + JSON.stringify(error));
            this.showToast('ERROR', error, 'error', 'default');
        })
    }

		changeSpinnerParentON(){
            /*
			const valueChangeEvent = new CustomEvent("spinneron");
			// Fire the custom event
			this.dispatchEvent(valueChangeEvent);
            */
            this.showSpinner()
		}


    processOrder(){
		console.log('inicio processOrder');
        if (!this.hasProducts) {
            this.showToast('Error', 'Option disabled', 'error', 'default');
            this.closeSpinner();
            return;
        }
        this.getCheckedProducts();
        console.log('this.productStockList:'+this.productStockList.length);
        console.log('this.uncheckedProducts:'+this.uncheckedProducts.length);
        //VALIDACION. SI EL TOTAL DE PRODUCTOS ES IGUAL AL TOTAL DE NO SELECCIONADOS -> MENSAJE
        if(this.productStockList.length == this.uncheckedProducts.length){
            this.showToast('Warning', 'You must select at least one product to continue with the order.', 'warning', 'default');
            this.changeSpinnerParentOFF();
            return;
        }

        if(this.uncheckedProducts.length != 0){
            deleteUncheckedProducts({orderId : this.recordId, productsToDelete: this.uncheckedProducts})
            .then((result) =>{
                console.log("RESULT: "+result);
                if(result != null){
                    if(result == 'OK'){
                        //this.sapSynchronize();
                        this.activateOrder();
                    }else {
                        if(result.includes('INSUFFICIENT_ACCESS_OR_READONLY')){
                            throw 'INSUFFICIENT_ACCESS_OR_READONLY';
                        }
												this.changeSpinnerParentOFF();
                    }
                }
            })
            .catch((error) =>{
                this.hasError = true;
                if(error.includes('INSUFFICIENT_ACCESS_OR_READONLY')){
                    this.showToast('Error', 'You cannot modify an order when its status is active.', 'error', 'default');
                }
                console.log('deleteUnchecked ERROR' + JSON.stringify(error));
                this.changeSpinnerParentOFF();
            })
        } else {
            if(this.checkedProducts.length != 0){
                this.activateOrder();
            }else{
                this.showToast('Error', 'You must select at least one item', 'error', 'default');
            }
        }

    }

    @api
    validateErrors(){
        return this.validationErrors;
    }

    handleCheckAll(e){
        let check = e.currentTarget.checked;
        let allchecks = this.template.querySelectorAll('input');

        allchecks.forEach(element => {
            element.checked = check;
        });
        this.productStockList.forEach(element => {
            element.available = check;
        });
    }
}