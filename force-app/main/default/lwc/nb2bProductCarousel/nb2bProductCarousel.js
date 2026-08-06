import { LightningElement, track } from 'lwc';
import getProducts  from '@salesforce/apex/Nb2b_ProductCarousel.getProductsInitial';
import {loadScript, loadStyle} from 'lightning/platformResourceLoader';
import FLICK from '@salesforce/resourceUrl/Flickity';

export default class Nb2bProductCarousel extends LightningElement {

    @track products = [];

    connectedCallback(){
	    this.getProducts();    
	}

    getProducts(){
        getProducts().then(result => {
            if(result){
                this.products = result;
                console.log('this.products: '+this.products);
                console.log('loading ssrr');
                Promise.all([
                    loadScript(this, FLICK + '/jqueryFlickity.js')
                ]).then(() => {
                    Promise.all([
                        loadStyle(this, FLICK + '/flickity.css')
                        ]).then(() => {                  
                            $(this.template.querySelector('div[class="carousel"]')).flickity({
                                cellAlign: 'center',
                                contain: true,
                                groupCells: true
                            });             
                        })
                    .catch(e => {
                        console.log('Error:' + e);
                    });
                }).catch(e => {
                    console.log('Error:' + e);
                });

                console.log('loaded');
            }
        }).catch(error => {
            console.log('Error : ' + JSON.stringify(error));
        });
    }
}