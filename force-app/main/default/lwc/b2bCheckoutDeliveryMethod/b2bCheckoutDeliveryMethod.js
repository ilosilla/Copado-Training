import { LightningElement, api } from 'lwc';

const K_SHIP_TO_CUSTOMER = 'SHIP-TO-CUSTOMER';
const K_CUSTOMER_PICKUP = 'CUSTOMER-PICKUP';

export default class B2bCheckoutDeliveryMethod extends LightningElement {

    /* =========================================================
     * PUBLIC API PROPERTIES
     * ========================================================= */
    @api 
    set deliveryMethod(value) {
        this.st_deliveryMethod = value ?? K_SHIP_TO_CUSTOMER;
    }       
    get deliveryMethod() {
        return this.st_deliveryMethod;
    }

    @api mode = 'edit'; 

    /* =========================================================
     * OUTGOING EVENTS
     * ========================================================= */
    emitConfirmDeliveryMethod() {        
        this.dispatchEvent(new CustomEvent('confirmdata', { detail: { deliveryMethod: this.st_deliveryMethod } }));
    }

    emitChangeDeliveryMethod() {
        this.dispatchEvent(new CustomEvent('changedata'));
    }

    /* =========================================================
     * INTERNAL STATE
     * ========================================================= */
    st_deliveryMethod;    

    /* =========================================================
     * GETTERS (JS convenience)
     * ========================================================= */    
    get isShipToCustomer() {
        return this.st_deliveryMethod === K_SHIP_TO_CUSTOMER;
    }

    get isPickup() {
        return this.st_deliveryMethod === K_CUSTOMER_PICKUP;
    }

    get isEditing() {
        return this.mode === 'edit';
    }

    /* =========================================================
     * TEMPLATE GETTERS (HTML-facing)
     * ========================================================= */
    get isConfirmDeliveryMethodDisabled() {
        return !this.st_deliveryMethod;
    }

    get deliveryMethodLabel() {
        return this.isShipToCustomer
            ? 'Ship to my address'
            : 'Pick up at warehouse';
    }

    /* =========================================================
     * EVENT HANDLERS
     * ========================================================= */
    handleDeliveryMethodChange(event) {
        this.st_deliveryMethod = event.currentTarget.value;
    }

    handleConfirm() {
        this.emitConfirmDeliveryMethod();
    }

    handleChange() {
        this.emitChangeDeliveryMethod();
    }


}