import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
//[TODO]:Implements method handleChange in js 'b2b_sapAccountingInfo.js'

export default class B2B_UtilsLWC extends NavigationMixin(LightningElement) {

    handleChange(event) {
        // Get the string of the "value" attribute on the selected option
        const selectedOption = event.detail.value;
        this.chosenValue = selectedOption;
    }
}