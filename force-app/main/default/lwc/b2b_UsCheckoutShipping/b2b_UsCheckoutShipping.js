import { LightningElement, api} from 'lwc';
import { useCheckoutComponent } from "commerce/checkoutApi";

const TARGET_NAME = 'Customer Collect';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: "CHECK_VALIDITY_UPDATE",
    REPORT_VALIDITY_SAVE: "REPORT_VALIDITY_SAVE",
    BEFORE_PAYMENT: "BEFORE_PAYMENT",
    PAYMENT: "PAYMENT",
    BEFORE_PLACE_ORDER: "BEFORE_PLACE_ORDER",
    PLACE_ORDER: "PLACE_ORDER",
};

export default class B2b_UsCheckoutShipping extends useCheckoutComponent(LightningElement) {

    /*----------------------------------
     |            PUBLIC API
     *----------------------------------*/
    @api
        get title() {
            return this._title;
        }
        set title(value) {
            this._title = value;
            console.debug('El title es ' + JSON.stringify(value));
        }

    @api 
        get checkoutAddresses() {
            return this._checkoutAddresses;
        }
        set checkoutAddresses(value) {
            this._checkoutAddresses = value;
            console.debug('El checkoutAddresses es ' + JSON.stringify(value));
        }

    @api
        get checkoutDetails() {
            return this._checkoutDetails;
        }
        set checkoutDetails(value) {
            this._checkoutDetails = value;
            console.debug('El checkoutDetails es ' + JSON.stringify(value));
        }

    @api
        get checkoutCartDetails() {
            return this._checkoutCartDetails;
        }
        set checkoutCartDetails(value) {
            this._checkoutCartDetails = value;
            console.debug('El checkoutCartDetails es ' + JSON.stringify(value));
        }

    /*----------------------------------
     |        PRIVATE STATE / DATA
     *----------------------------------*/    
    isLoading = false;
    _checkoutAddresses;
    _checkoutDetails;
    _checkoutCartDetails;
  
    /*----------------------------------
     |               GETTERS
     *----------------------------------*/     
    get myOptions() {
        return [
            { value: '1', label: 'Nombre', description: 'Extra info' },
            { value: '2', label: 'Otra opción' }
        ]
    }

    get selectedValue() {
        return 1;
    }

    handleCambia() {
        console.log('CAMBIOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO')
        const newaddress = {...this._checkoutAddresses.items[1]};
        this.updateCheckoutDetails(newAddress);
    }

    // Ejemplo: actualizar Checkout.Details (por ejemplo método de envío)
    async updateCheckoutDetails(newDetails) {
        const deliveryGroup = {}
        deliveryGroup.deliveryAddress = newDetails;
        this.isUpdating = true;
        try {
            const updatedCheckout = await this.dispatchUpdateAsync({
                field: 'deliveryGroup',
                updates: newDetails
            });

            console.log('==================> YA HE VUELTO DEL METODO Y ME DA ' + JSON.stringify(updatedCheckout));

            // MUY IMPORTANTE: reemplazar el objeto completo para que el template re-renderice
            //this.checkout = updatedCheckout;
        } catch (error) {
            // aquí ya metes tu logger / toast / lo que uses
            // eslint-disable-next-line no-console
            console.error('Error updating checkout details', error);
        } finally {
            this.isUpdating = false;
        }
    }
}