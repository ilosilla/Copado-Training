import { LightningElement , wire, track, api } from 'lwc';
import getUserRoles from '@salesforce/apex/B2B_SapAccountingInfoController.getUserRoles';
//import B2B_LwcUtils from '../b2B_LwcUtils/B2B_UtilsLWC';

let i = 0;

export default class b2B_SapAccountingInfo extends LightningElement {
    //export default class b2B_SapAccountingInfo extends B2B_UtilsLWC {

    @api recordId;
    @track items = []; //this will hold key, value pair
    value = ''; //initialize combo box value
    @api chosenValue = '';


    @wire(getUserRoles, { recordIdStr: '$recordId' })
    wiredUserRoles({ error, data }) {
        if (data) {

            for(i=0; i<data.length; i++)  {
                this.items = [...this.items ,{value: data[i].Id , label: data[i].Name} ];
                console.log(data[i].Id);
            }

            if(data.length === 1){
                this.chosenValue = data[0].Id;
            }else{
                this.chosenValue = 'No existe objeto asociado 2';//Meter en customLabel
            }//end if

            



        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }

    //gettter to return items which is mapped with options attribute
    get roleOptions() {
        return this.items;
    }

    handleChange(event) {
        // Get the string of the "value" attribute on the selected option
        const selectedOption = event.detail.value;
        this.chosenValue = selectedOption;
        const attributeChangeEvent = new FlowAttributeChangeEvent('chosenValue', this.chosenValue);
        this.dispatchEvent(attributeChangeEvent);
    }

    //this value will be shown as selected value of combobox item
    get selectedValue(){
        return this.chosenValue;
    }

}//end export