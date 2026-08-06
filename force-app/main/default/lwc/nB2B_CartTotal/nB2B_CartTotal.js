import { LightningElement,track,wire,api }  from 'lwc';

//LABELS
import NB2B_Total_Component_Text            from '@salesforce/label/c.NB2B_Total_Component_Text';
//APEX
import getCartTotal                         from '@salesforce/apex/NB2B_CartTotal.getCartTotal';
import getSessionId                         from '@salesforce/apex/NB2B_CartTotal.getSessionId';
import getTaxex                             from '@salesforce/apex/NB2B_CartTotal.getTaxex';
import calculateTaxes                       from '@salesforce/apex/NB2B_CartTotal.calculateTaxex';

//PLATFORM EVENT
import cometdlwc                            from "@salesforce/resourceUrl/cometd";
import { loadScript }                       from "lightning/platformResourceLoader";


export default class NB2B_CartTotal extends LightningElement {

    labels = {
        NB2B_Total_Component_Text
    }
    @api    recordId;
    @api    cartId;
    @track  showTotals = true;
    @track  totalS;
    @track  total;
    @track  subTotalS;
    @track  subTotal;
    @track  valorImpuestosS;
    @track  valorImpuestos;
    @track  porcentajeTasasS;
    @track  porcentajeTasas;
    @track  currencyCart;
    @track  taxexName;
    @track  error;
    @track  country;
    @track  currencyS;
    

    connectedCallback(){
        this.getInitAmount();
        this.country = 'United_Kingdom';
        this.getTaxex();
    }

    getInitAmount(){
        getCartTotal({recordId : this.cartId})
            .then(result => {
                // console.log('getCartTotal:'+JSON.stringify(result));
                this.subTotal       = result.amount;
                this.subTotalS      = result.amount;
                this.currencyCart   = result.currencyCart;
                // console.log('getInitAmount VALORES:');
                // console.log('this.subTotal:'*this.subTotal);
                // console.log('this.subTotalS:'*this.subTotalS);
                // console.log('this.currencyCart:'*this.currencyCart);
            })
            .catch(error => {
                this.error = error;
            });
    }

    getTaxex(){
        console.log('getTaxex');
        getTaxex({countryS : this.country})
            .then(result => {
                console.log('result getTaxex:'+JSON.stringify(result));
                this.taxexName          = result.name;
                this.porcentajeTaxex    = result.percent;
                this.currencyS          = result.currencyS;

                this.calculatePrices(this.subTotal);

            })
            .catch(error => {
                this.error = error;
            });
    }

    calculatePrices(amountT){
        // console.log('calculatePrices amount(subtotal):'+amountT);
        // console.log('calculatePrices porcentajeTaxex:'+this.porcentajeTaxex);
        calculateTaxes({amount : amountT, porcentTaxex: this.porcentajeTaxex, currencyCart: this.currencyCart})
            .then(result => {
                // console.log('result calculatePrices:'+JSON.stringify(result));
                this.totalS             = result.valueTotalS;
                //this.subTotalS          = result.valueSubTotalS;
                this.valorImpuestosS    = result.valueCalculoImpS;

                this.total              = result.valueTotal;
                this.subTotal           = result.valueSubTotal;
                this.valorImpuestos     = result.valueCalculoImp;
                // console.log('calculatePrices VALORES:');
                // console.log('this.total:'+this.total);
                // console.log('this.subTotal:'+this.subTotal);
                // console.log('this.subTotalS:'+this.subTotalS);
                // console.log('this.valorImpuestosS:'+this.valorImpuestosS);
                // console.log('this.currencyCart:'+this.currencyCart);
            })
            .catch(error => {
                this.error = error;
            });
    }

    /** PLATFORM EVENTS */
    libInitialized = false;
    @track sessionId;
    @track error;

    @wire(getSessionId)
    wiredSessionId({ error, data }) {
    if (data) {
        this.sessionId = data;
        this.error = undefined;
        loadScript(this, cometdlwc)
        .then(() => {
            this.initializecometd()
        });
    } else if (error) {
        console.log(error);
        this.error = error;
        this.sessionId = undefined;
    }
    }

    initializecometd() {
        if (this.libInitialized) {
            return;
        }
        this.libInitialized = true;
        //inintializing cometD object/class
        var cometdlib = new window.org.cometd.CometD();
        //Calling configure method of cometD class, to setup authentication which will be used in handshaking
        cometdlib.configure({
            url: window.location.protocol + '//' + window.location.hostname + '/cometd/47.0/',
            requestHeaders: { Authorization: 'OAuth ' + this.sessionId},
            appendMessageTypeToURL : false,
            logLevel: 'debug'
        });

        cometdlib.websocketEnabled = false;
        cometdlib.handshake((status) => {
            if (status.successful) {
                // Successfully connected to the server.
                // Now it is possible to subscribe or send messages
                let self = this;
                cometdlib.subscribe('/event/NB2B_ChangeWebCartTotalAmount__e',(msg) => {
                        self.manageResponse(msg);
                });
            } else {
                /// Cannot handshake with the server, alert user.
                console.error('Error in handshaking: ' + JSON.stringify(status));
            }
    });
    }

    manageResponse(message){
        let cart = message?.data?.payload?.NB2B_WebCartId__c;
        let amount = message?.data?.payload?.NB2B_TotalAmountStr__c;
        if(cart != null && this.cartId == cart){
            if(amount != null){
                console.log('manageResponse amount: '+amount);
                //Directamente dar valor a subtotal
                this.subTotalS = amount;

               
                    // var subTotalSS = amount.replace('.','');
                    // var str = subTotalSS.replace(',','.');
                    
                    // this.calculatePrices(parseFloat(str).toFixed(2));
                
                    this.calculatePrices(amount);
                
                
            }
        }
    }
    /** PLATFORM EVENTS */
}