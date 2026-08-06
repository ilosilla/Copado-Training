import { LightningElement, wire } from "lwc";
import {publish,MessageContext} from "lightning/messageService";

import cartChanged from "@salesforce/messageChannel/lightning__commerce_cartChanged";
import { CartSummaryAdapter, refreshCartSummary } from "commerce/cartApi";


export default class NBK_EmptyWebCartIcon extends LightningElement {

	@wire(MessageContext)
	messageContext;

	connectedCallback() {
		this.doRefreshCartSummary();
	}


	doRefreshCartSummary() {

        refreshCartSummary().then(() => {

            console.log("cart summary refreshed");

        });

     }
}