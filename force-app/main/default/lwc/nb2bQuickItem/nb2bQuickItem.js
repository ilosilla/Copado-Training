/**
 * @description  : 
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 22-09-2023
 * @group        : 
 * @see          : 
**/
import { LightningElement, api, track, wire } from "lwc";
import LwcUtils from 'c/lwcUtils';
import getProduct from '@salesforce/apex/NB2B_QuickOrderController.getProductAndPrice';
import LOCALE from '@salesforce/i18n/locale';

export default class Nb2bShippingAdress extends LightningElement {

    cartItem = {};
    @track qntIntroduced = false;
    @track searchTerm;
    @track showError = false;
    @track showProduct = false;
    @track product = {};
	@api cartItem;
    @api index;

    get salesPrice(){
        return this.calculateSalesPrice().toLocaleString(LOCALE);
    }

    calculateSalesPrice(){
        let salesPrice = this.product.price.UnitPrice;
        try{
            if(this.product.product.Umv__c != this.product.price.Uprice__c){
                if(this.product.product.UmbMt2__c > 0){
                    //PRODUCTO DE TIPO AREA
                    //1- COMPROBAMOS SI SE COMPRA EN PIEZAS O EN CAJAS - UNIDAD DE VENTA
                    if(this.product.product.Umv__c == 'PZS' || this.product.product.Umv__c == 'UN'){
                        //SE COMPRA EN PIEZAS
                        if(this.product.price.Uprice__c == 'PZS' || this.product.price.Uprice__c == 'UN'){
                            salesPrice = Math.floor(this.product.price.UnitPrice* 100)/100;
                        //2- COMPROBAMOS DIRECTAMENTE EL PRECIO EN CAJAS? COMPROBAR EN PROD SI HAY VARIOS PRODUCTOS QUE CAMBIE EL VALOR ENTRE UN Y PZS
                        }else if(this.product.price.Uprice__c == 'CJ' || this.product.price.Uprice__c == 'BOX' || this.product.price.Uprice__c == 'CV'){
                            //EL PRECIO VA POR CAJA, HAY QUE CALCULAR CUÁNTO CUESTA CADA PIEZA
                            salesPrice = Math.floor(this.product.price.UnitPrice / this.product.product.PcsXBox__c * 100)/100;
                        }else if(this.product.price.Uprice__c == 'M2' || this.product.price.Uprice__c == 'MT2'){
                            //PRECIO POR MT2, HAY QUE CALCULAR EL PRECIO POR CADA PIEZA
                            salesPrice = Math.floor(this.product.price.UnitPrice * (Math.floor(this.product.product.M2XBox__c * 1000)/1000) / this.product.product.PcsXBox__c * 100)/100;
                        }
                    }else if(this.product.product.Umv__c == 'CJ' || this.product.product.Umv__c == 'BOX' || this.product.price.Uprice__c == 'CV'){
                        //SE COMPRA EN CAJAS
                        if(this.product.price.Uprice__c == 'CJ' || this.product.price.Uprice__c == 'BOX' || this.product.price.Uprice__c == 'CV'){
                            salesPrice = Math.floor(this.product.price.UnitPrice* 100)/100;
                        }else if(this.product.price.Uprice__c == 'M2' || this.product.price.Uprice__c == 'MT2'){
                            salesPrice = Math.floor(this.product.price.UnitPrice * (Math.floor(this.product.product.M2XBox__c * 1000)/1000) * 100)/100;
                        }else if(this.product.price.Uprice__c == 'PZS' || this.product.price.Uprice__c == 'UN'){
                            salesPrice = Math.floor(this.product.price.UnitPrice * this.product.product.PcsXBox__c * 100)/100;
                        }
                    }
                }else{
                    //PRODUCTO DE TIPO PESO, SI TUVIERA MISMA UNIDAD DE COMPRA Y PRECIO SE HABRÁ CALCULADO YA, HAY QUE CALCULAR EN FUNCIÓN DEL PESO
                    if(this.product.product.UmbKg__c != null && this.product.price.Uprice__c == 'KG'){
                        salesPrice = Math.floor(this.product.product.UmbKg__c * this.product.price.UnitPrice * 100)/100;
                    }
                }
            }
        }catch(e){ console.error(e); }
        console.log(salesPrice);
        return salesPrice;
    }
    handleOncommit(inputValue){
        console.log('handleOnComit');
        this.searchTerm = inputValue.trim();
        //VALIDAMOS SI HAY ALGO EN EL CUADRO DE BUSQUEDA
        if(this.searchTerm != null && this.searchTerm != undefined ){
            console.log('this.searchTerm :'+this.searchTerm );

            if(this.searchTerm == ''){
                //VACIAMOS ESE CARTITEM
                let cartIt =  JSON.parse(JSON.stringify(this.cartItem));
                cartIt.productInfo = {};
                cartIt.total = 0;
                cartIt.quantity = 0;
                this.cartItem = cartIt;
                this.showError = false;
                this.showProduct = false;

               //actualizar el carrito
               this.updateCart();

            }else if(this.searchTerm != ''){
                console.log('CUADRO DE BUSQUEDA RELLENO');
                //BUSQUEDA RELLENA. CON LO CUAL BUSCAMOS PRODUCTO
                getProduct({ searchTerm: this.searchTerm })
                .then((result) => {
                    console.log('result :', JSON.parse(JSON.stringify(result)));

                    let cartIt =  JSON.parse(JSON.stringify(this.cartItem));
                    if(result == null){
                        cartIt.productInfo = {};
                        cartIt.total = 0;
                        cartIt.quantity = 0;
                        this.cartItem = cartIt;
                        this.showError = true;
                        this.showProduct = false;
                    }else{
                        if(result.isCorrect){
                            cartIt.productInfo =result;
                            cartIt.total = 0;
                            cartIt.quantity = 0;
                            this.cartItem = cartIt;
                            this.product = result;
                            if(result != null){
                                this.showProduct = true;
                            }
                            this.showError = false;
                            this.showProduct = true;
                        }else{
                            cartIt.productInfo = {};
                            cartIt.total = 0;
                            cartIt.quantity = 0;
                            this.cartItem = cartIt;
                            this.showError = true;
                            this.showProduct = false;
                        }
                    }
                    //actualizar el carrito
                    this.updateCart();
                })
                .catch((error) => {
                    this.product = error;
                    this.showProduct = false;
                });

            }
        }else{
            console.log('busqueda null');
        }
        
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        getProduct({ searchTerm: this.searchTerm })
            .then((result) => {
                this.cartItem.productInfo = result;
            })
            .catch((error) => {
                this.cartItem.productInfo = error;
            });
    }

    updateCart() {
        const selectedEvent = new CustomEvent('addtocart', { detail: {cartItem: this.cartItem, index: this.index}});
        this.dispatchEvent(selectedEvent);
    }

    validateFields(){
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        if (isInputsCorrect) {
            return true;
        }else{
            return false;
        }
    }

    calculateTotals(event) {
        console.log("locale: "+JSON.stringify(Intl.NumberFormat(LOCALE)));
        try{
            // console.log('calculateTotals');
            this.qntIntroduced = true;
            let cartItemAux =  JSON.parse(JSON.stringify(this.cartItem));
            // cartItemAux.quantity = parseInt(event.target.value);
            // console.log("LOCALE: "+LOCALE);
            // cartItemAux.quantity = Intl.NumberFormat(LOCALE).format(event.target.value);
            // console.log("sin transformar: "+event.target.value.replace(',', '.'));
            // console.log("transformar: "+Intl.NumberFormat(LOCALE).format(event.target.value.replace(',', '.')));
            // console.log("transformar sin decimal: "+Intl.NumberFormat(LOCALE, {maximumFractionDigits: 0}).format(event.target.value.replace(',', '.')));
            // console.log("transformar sin decimal: "+Intl.NumberFormat(LOCALE, {maximumFractionDigits: 0}).format(event.target.value.replace(',', '.')));
            if (parseInt(event.target.value) > 999 || isNaN(Intl.NumberFormat(LOCALE, {maximumFractionDigits: 0}).format(event.target.value.replace(',', '.')))){
                cartItemAux.quantity = this.cartItem.quantity;
                this.template.querySelector("[data-id='quantityField']").value = cartItemAux.quantity;
            }else{
                cartItemAux.quantity = Intl.NumberFormat(LOCALE, {maximumFractionDigits: 0}).format(event.target.value.replace(',', '.'));
                console.log('quantity',cartItemAux.quantity);
                this.cartItem = cartItemAux;
                this.template.querySelector("[data-id='quantityField']").value = cartItemAux.quantity;
            }

            if(cartItemAux.quantity){
                //hacemos los cálculos de precio en función de la unidad de venta y la unidad de precio
                if(this.showProduct && this.product != null){
                    cartItemAux.total = this.calculateSalesPrice() * cartItemAux.quantity;
                    cartItemAux.total = Math.floor(cartItemAux.total * 100)/100;
                }
            }else{
                cartItemAux.total = 0;
            }
            this.cartItem = cartItemAux;
            this.updateCart();
        }catch(e){
            console.error(e);
        }
    }

    handleSearchChange(event) {
        clearTimeout(this.timeoutId); // no-op if invalid id
        console.log('handle');
        var term = event.target.value;
        this.timeoutId = setTimeout(() => this.handleOncommit(term), 500);
    }
    
    doExpensiveThing(event) {
        console.log('expensive');
        this.handleOncommit(event);
    }

    deleteItem() {
        try {
            const detail = {
                guid: this.cartItem.guid,
            };
            const selectEvent = new CustomEvent('deleteitem', {
                bubbles: true,
                detail,
            });
            this.dispatchEvent(selectEvent);
        } catch (error) {
            console.error(error);
        }
    }
}