import { LightningElement, api } from 'lwc';

export default class B2bCheckoutHeader extends LightningElement {


    handleContinue() {
        this.dispatchEvent(new CustomEvent('continueshopping'));
    }

}