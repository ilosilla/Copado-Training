import { LightningElement, wire } from 'lwc';
import {publish,MessageContext} from "lightning/messageService";
import cartChanged from "@salesforce/messageChannel/lightning__commerce_cartChanged";

export default class NB2B_UpdateCartCount extends LightningElement {

    @wire(MessageContext)
    messageContext;
    
    connectedCallback(){
        this.updateCartCount();
    }

    updateCartCount(){
        this.dispatchEvent(new CustomEvent("cartchanged", {
            bubbles: true,
            composed: true
          }));
    }
}