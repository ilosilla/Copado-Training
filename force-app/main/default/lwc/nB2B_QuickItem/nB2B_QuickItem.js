import { LightningElement, api, track, wire } from "lwc";
import LwcUtils from 'c/lwcUtils';
import getProduct from '@salesforce/apex/NB2B_QuickOrderController.getProductAndPrice';

export default class Nb2bShippingAdress extends LightningElement {

    cartItem = {};
    searchTerm = '';

    @track searchTerm;
	@api cartItem;

    handleSearch() {
        getProduct({ searchTerm: this.searchTerm })
            .then((result) => {
                this.cartItem = result;
            })
            .catch((error) => {
                this.cartItem = result;
            });
    }

    calculateTotals() {
        //hacemos los cálculos de precio en función de la unidad de venta y la unidad de precio
        if(this.cartItem.showProductData && this.cartItem.quantity > 0 && this.cartItem.productInfo != null){
            //COMPROBAMOS PRIMERO SI LA UNIDAD DE VENTA ES LA MISMA QUE LA DE COMPRA, SI ES ASÍ LA RELACIÓN DE PRECIO ES DE 1 = 1
            this.cartItem.total = this.cartItem.productInfo.price.UnitPrice * this.cartItem.quantity;

            
            /*if(this.cartItem.productInfo.productUnit == this.cartItem.productInfo.productUnit.priceUnit){
                console.log('this.cartItem.productInfo.price.UnitPrice:'+this.cartItem.productInfo.price.UnitPrice);
                console.log('this.cartItem.quantity:'+this.cartItem.quantity);
                

            }else{
                if(this.cartItem.productInfo.product.UmbMt2__c > 0){
                    //PRODUCTO DE TIPO AREA
                    //1- COMPROBAMOS SI SE COMPRA EN PIEZAS O EN CAJAS - UNIDAD DE VENTA
                    if(this.cartItem.productInfo.productUnit == 'PZS' || this.cartItem.productInfo.productUnit == 'UN'){
                        //SE COMPRA EN PIEZAS
                        //2- COMPROBAMOS DIRECTAMENTE EL PRECIO EN CAJAS? COMPROBAR EN PROD SI HAY VARIOS PRODUCTOS QUE CAMBIE EL VALOR ENTRE UN Y PZS
                        if(this.cartItem.productInfo.priceUnit == 'CJ' || this.cartItem.productInfo.priceUnit == 'BOX'){
                            //EL PRECIO VA POR CAJA, HAY QUE CALCULAR CUÁNTO CUESTA CADA PIEZA
                            this.cartItem.total = this.quantity * (this.cartItem.productInfo.price.UnitPrice / this.cartItem.productInfo.product.UmbCj__c);      
                        }else if(this.cartItem.productInfo.priceUnit == 'MT2'){
                            //PRECIO POR MT2, HAY QUE CALCULAR EL PRECIO POR CADA PIEZA
                            this.cartItem.total = this.quantity * this.cartItem.productInfo.price.UnitPrice * (this.cartItem.productInfo.price.UmbCj__c / this.cartItem.productInfo.product.UmbMt2__c);  
                        }
                        
                    }else if(this.cartItem.productInfo.productUnit == 'CJ' || this.cartItem.productInfo.productUnit == 'BOX'){
                        //SE COMPRA EN CAJAS
                        if(this.cartItem.productInfo.priceUnit == 'CJ' || this.cartItem.productInfo.priceUnit == 'BOX'){
                            this.cartItem.total = this.quantity * this.cartItem.productInfo.price.UnitPrice;

                        }else if(this.cartItem.productInfo.priceUnit == 'MT2'){
                            this.cartItem.total = this.quantity * this.cartItem.productInfo.price.UnitPrice * this.cartItem.productInfo.product.UmbMt2__c;

                        }else if(this.cartItem.productInfo.priceUnit == 'PZS' || this.cartItem.productInfo.priceUnit == 'UN'){
                            this.cartItem.total = this.quantity * this.cartItem.productInfo.price.UnitPrice * this.cartItem.productInfo.product.UmbCj__c;
                        }

                    }

                }else{
                    //PRODUCTO DE TIPO PESO, SI TUVIERA MISMA UNIDAD DE COMPRA Y PRECIO SE HABRÁ CALCULADO YA, HAY QUE CALCULAR EN FUNCIÓN DEL PESO
                    if(this.cartItem.productInfo.productUnit == 'KG'){
                        this.cartItem.total = this.quantity * this.cartItem.productInfo.UmbKg__c * this.cartItem.productInfo.price.UnitPrice;
                    }else{
                        this.cartItem.total = this.quantity * this.cartItem.productInfo.price.UnitPrice;
                    }

                }
            }*/
        }
    }
}