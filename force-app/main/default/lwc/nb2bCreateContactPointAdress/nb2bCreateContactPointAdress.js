import { LightningElement, api } from 'lwc';

export default class Nb2bCreateContactPointAdress extends LightningElement {

    @api accountId;
    @api recordId;
    strStreet;
    strCity;
    strState;
    strCountry;
    strPostalCode;
    addressType = 'Shipping';

    closeModal() {
        try{
            this.dispatchEvent(new CustomEvent('showcreatecpa'));
        } catch(e){ console.error(e); }
    }
    handleSave(event){
        event.preventDefault();
        let fields = event.detail.fields;
        fields.Street = this.strStreet;
        fields.City = this.strCity;
        fields.State = this.strState;
        fields.Country = this.strCountry;
        fields.PostalCode = this.strPostalCode;

        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.closeModal();
    }

    handleSuccess(event){
        console.log('address created: '+event.detail.id);
        this.dispatchEvent(new CustomEvent('updateaddresseslist',{ detail:event.detail.id}));//event to dispatch is if succes

    }

    addressInputChange(event){
        this.strStreet = event.target.street;
        this.strCity =  event.target.city;
        this.strState = event.target.province;
        this.strCountry = event.target.country;
        this.strPostalCode = event.target.postalCode;

    }
}