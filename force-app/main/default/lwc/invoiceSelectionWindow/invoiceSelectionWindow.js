import { LightningElement } from 'lwc';

export default class InvoiceSelectionWindow extends LightningElement {
    handleCancel() {
        // Fire the custom event
        this.dispatchEvent(new CustomEvent('cancel', {}));    
   }
}