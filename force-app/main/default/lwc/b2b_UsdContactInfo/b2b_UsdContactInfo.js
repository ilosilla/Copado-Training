import { LightningElement, api } from 'lwc';

export default class B2b_UsdContactInfo extends LightningElement {

    @api 
        get cartDetails() {
            return this._cartDetails;
        }
        set cartDetails(value) {
            console.debug('=======> ' + value + ' and ' + JSON.stringify(value));
            this._cartDetails = value;
        }

    _cartDetails;

}