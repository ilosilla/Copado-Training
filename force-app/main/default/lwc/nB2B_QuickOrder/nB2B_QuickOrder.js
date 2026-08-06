/**
 * @description  : 
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 22-09-2023
 * @group        : 
 * @see          : 
**/
import { track, wire } from "lwc";
import LwcUtils from 'c/lwcUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContactList from '@salesforce/apex/NB2B_QuickOrderController.getInit';
import addToCart from '@salesforce/apex/NB2B_QuickOrderController.addToCart';
import {MessageContext} from "lightning/messageService";



export default class Nb2bShippingAdress extends LwcUtils {
	

    idWebCart;
    cartItemListAux = [];

	@track cartItemList = [];
    @track total = 0;
    @track error;
    @track currencyIsoCode = '';
    @track alertAddProduct = false;

    get disableAdd(){
        return (this.cartItemList && this.cartItemList.length)
            ? !this.cartItemList.reduce((totalQuantity,item)=>{
                totalQuantity += (item.quantity > 0)? item.quantity : 0;
                return totalQuantity;
            },0)
            : true;
    }

    @wire(MessageContext)
    messageContext;


    getDoInitHandler(){
        getContactList()
            .then(result => {
                this.cartItemList = result;
                this.cartItemList[0] = {
                    ...result[0],
                    guid: this.guid(),
                }
                this.cartItemListAux = result;
                this.currencyIsoCode = result[0].currencyIsoCode;
            })
            .catch(error => {
                this.error = error.body.message;
            });
    }
	

    connectedCallback() {
        getContactList()
            .then(result => {
                this.currencyIsoCode = result[0].currencyIsoCode;
                this.cartItemList = result;
                this.cartItemList[0] = {
                    ...result[0],
                    guid: this.guid(),
                }
            })
            .catch(error => {
                this.error = error.body.message;
            });    
    }
    updateCart(event) {
        this.error = null;
        this.cartItemList[event.detail.index] = event.detail.cartItem;
        this.cartItemListAux[event.detail.index] = event.detail.cartItem;
        this.recalculateCartTotal();
    }

    recalculateCartTotal() {
        this.total = 0;
        for(let i =0; i< this.cartItemList.length; i++){
            this.total += this.cartItemList[i].total;
        }
        this.total = Math.floor(this.total * 100)/100;
    }

    addToCart() {
        let dataOrg = window.sessionStorage.getItem('salesOrgId');
        this.error = null;

        let itmesToAdd = this.cartItemList.filter((item)=>{ return (item.quantity && item.productInfo); });

		addToCart({ jsonWrapper: JSON.stringify(itmesToAdd), salesOrg: dataOrg })
            .then(result => {
                if(result.success == true){
                    this.error = null;
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Items added to cart',
                        variant: 'info',
                    });
                    this.dispatchEvent(evt);
                    
                    this.cartItemList = [{
                        guid: this.guid(),
                        quantity: 0,
                        showProductData: false,
                        showSearch: true,
                        total: 0,
                        productInfo: {}
                    }];

                    setTimeout(() => {
                        try{
                            eval("$A.get('e.force:refreshView').fire();");
                        }catch(e){
                            console.error(e);
                        }
                   }, 500);

                   this.dispatchEvent(new CustomEvent("cartchanged", {
                    bubbles: true,
                    composed: true
                  }));
                    
                }else{
                    this.error = 'Please review these errors before continuing: ' + this.prettifyError(result.errorMsg);
                }
            })
            .catch(error => {
                this.error = this.prettifyError(error.body.message);                
            });
	}
    prettifyError(errorMsg){
        let finalError = errorMsg;
        try{
            let regEx = /^.*_EXCEPTION,\s(.*):\s\[.*$/;
            let result = regEx.exec(errorMsg);
            finalError = (result)? result.slice(1) : errorMsg;
        }catch(e){console.error(e);}
        return finalError;
    }

    addLines() {
        const canAddProduct = this.cartItemList.reduce(
            (allQntGreaterThan0, item) => (allQntGreaterThan0 && item.total>0),
            true
        );

        if(canAddProduct){
            this.cartItemList.push({
                guid: this.guid(),
                quantity: 0,
                showProductData: false,
                showSearch: true,
                total: 0,
                productInfo: {},
            });
        }else{
            this.alertAddProduct = true;
            setTimeout(() => {
                this.alertAddProduct = false;
            }, "5000");
        }

        //console.log(`NB2B_QuickOrder - addLines() - cartItemList:`, JSON.parse(JSON.stringify(this.cartItemList)));
	}

    handleItemDeletion(event) {
        try {
            //console.log(`NB2B_QuickOrder - addLines() - cartItemList [BEFORE DELETE]:`, JSON.parse(JSON.stringify(this.cartItemList)));
            const guid = event.detail.guid;
            const itemIdx = this.cartItemList.findIndex(item => item.guid===guid);
            this.cartItemList.splice(itemIdx, 1);
            //console.log(`NB2B_QuickOrder - addLines() - cartItemList [AFTER DELETE]:`, JSON.parse(JSON.stringify(this.cartItemList)));
            this.recalculateCartTotal();
        } catch (error) {
            console.error(error);
        }
    }
}