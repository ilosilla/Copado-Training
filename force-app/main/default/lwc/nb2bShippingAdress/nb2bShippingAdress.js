import { LightningElement, wire, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import LwcUtils from 'c/lwcUtils';
//import labels from 'c/createOrderLabels';//
//import getAddresses from '@salesforce/apex/NB2B_AddressController.getAddresses';

export default class Nb2bShippingAdress extends LwcUtils {

    @api recordId;
    @api accountId;
    @api pointContactAddressId;//=addressId
    @api postalCode;
    @api addressId;
    /* @api adressPostalCodeAndId = {
        postalCode : this.postalCode,
        pointContactAddressId : this.pointContactAddressId
    }; */
    @api edit = false;

    address;
    addresses;
    selectedAddress;
    mappedAddresses = [];
    //labels = labels;
    @track createContactPointAddress = false;
    @track showContactPointAddress = false;
    error;
    @track sapIdCPA;



    get modalTitle() {
        return "Add Address";
        //return join(' ', labels.Add, labels.Address);
    }

    connectedCallback() {
        this.addEventListener('doInit', this.getDoInitHandler(this));
        this.retrieveData();
        //this.getAddressesList();       
    }

    retrieveData() {
		try{
			// console.log('Nb2bShippingAdress - retrieveData()');
            super.fetch('NB2B_AddressController','getAddresses',{webcartId: this.recordId});
		}catch(e){ this.setError(e, this); }
	}

	getDoInitHandler() {
		// console.log('Nb2bShippingAdress - getDoInitHandler()');
		return function(event){
			try{
				const data = this.handleDoInit(event);
				// console.log('Nb2bShippingAdress - getDoInitHandler() - [data]:', JSON.parse(JSON.stringify(data)));

				this.fillAddressData(data, null);
                this.edit = true;
			}catch(e){ this.setError(e, this); }
		};
	}

    setError(error, self){
        self.error = error;
        self.addresses = [];
        console.error(e);
    }

    reloadDataPrube(addressId){
        // console.log('Metodo reload');
        try{
            this.retrieveData();
            
        }catch(e){ this.setError(e, this); }
    }

    fillAddressData(data, addressIdSelected){
        let options = [];
        let sapIds = [];
        let mappedAddressesTemp = [];
        let accountSelected;
        //temp variables for init case when rendender the component
        let addressTemp;
        //let sapIdTemp;
        // console.log('dato pasado: ' + data);
        data.forEach(element => {

            let normalizedAddress = ' ' + element.Address.street + ' ' + 
                                                element.Address.city + ' ' +  
                                                element.Address.state + ' ' +  
                                                element.Address.country + ' ' +  
                                                element.Address.postalCode+ ' ' + (element.IsDefault?'(Domicilio Principal)':'');
                                               
                                                // console.log('elemento normalizado: ' + normalizedAddress);
            options.push({ label: normalizedAddress, value: element.Id});

            //sapIds[element.Id] = element.SAPId__c;
            mappedAddressesTemp[element.Id] = element;
            accountSelected = element.ParentId;

            //fill the temp variables for the case we are rendering the coponent for the firtst time
            if(element.IsDefault){
                addressTemp = element;
                //sapIdTemp = element.SAPId__c;
                //this.pointContactAddressId = element.Id;
                //this.postalCode = element.Address.postalCode;
                /* this.adressPostalCodeAndId.postalCode = this.postalCode;
                this.adressPostalCodeAndId.pointContactAddressId = this.pointContactAddressId; */
            }

        });
        handleChangeAddressToSend(this.adressPostalCodeAndId);
        this.mappedAddresses = mappedAddressesTemp
        this.addresses = options;
        this.accountId = accountSelected;


        //check the case we are reaload an addressId and maybe we have new address Id and the init case where we take the temp variables for the default case
        if(addressIdSelected != null && addressIdSelected != 'undefined'){
            var sel = [];
            sel.push(this.addressId);
            // console.log('Enter in modificate');
            this.selectedAddress = sel;
            this.sapIdCPA = sapIds[this.selectedAddress[0].SAPId__c];//todo revisar esta asidnación en el reload
        }else{
            var sel = [];
            sel.push(addressTemp);
            this.selectedAddress = sel;
            this.address = addressTemp.Address;
            //this.sapIdCPA = sapIdTemp;
        }
        // console.log('Adress que no debe aparecer en el mapa: ' + JSON.stringify(this.address));
        this.error = undefined;
    }

    //Abre el modal para los comentarios
    handleAddComment() {
        const dialog = this.template.querySelector('c-nb2b-dialog');
        dialog.show();
    }

    handleCancel() {
        const dialog = this.template.querySelector('c-nb2b-dialog');
        dialog.hide();
    }

    handleSave() {
        console.log('hide');
        const dialog = this.template.querySelector('c-nb2b-dialog');
        dialog.hide();
        try{
            this.fireGenericEvt('setOrderAddress', { address: this.selectedAddress });
        } catch(e){ console.error(e); }
    }

    handleAddress(event) {
        this.selectedAddress = event.detail.value;
        // console.log('Dato del evento a ver: ' + this.selectedAddress);
        // console.log('Address mostrada: ' + JSON.stringify(this.mappedAddresses[this.selectedAddress].Address));
        this.address = this.mappedAddresses[this.selectedAddress].Address;
        this.postalCode = this.address.postalCode;
        this.pointContactAddressId = this.selectedAddress;
        // console.log('Adress que debe aparecer en el mapa: ' + JSON.stringify(this.address));
        //const attributePostalCodeChangeEvent = new FlowAttributeChangeEvent('postalCode', this.postalCode);
        //this.dispatchEvent(attributePostalCodeChangeEvent);
        /* const objToSend = Object.create(adressPostalCodeAndId);
        this.adressPostalCodeAndId.postalCode = this.postalCode;
        this.adressPostalCodeAndId.pointContactAddressId = this.pointContactAddressId; */
        handleChangeAddressToSend(this.adressPostalCodeAndId);
    }
//
    handleModifyAddress() {
        this.showContactPointAddress = true;
    }

    handleHideModifyAddress() {
        this.showContactPointAddress = false;
    }

//
    handleAddNewAddress() {
        this.createContactPointAddress = true;
    }

    handleHideCreateCPA(){
        this.createContactPointAddress = false;
    }

    handleUpdateAddresses(event){                //-----------------------
        this.addressId = event.detail;
        this.selectedAddress = 
        //super.fetch('NB2B_AddressController','getAddresses',{webcartId: this.recordId});
        this.retrieveData()
        .then(() => { 
            this.fillAddressData(data, this.addressId);
        })
        .catch((e) => { this.setError(e, this); });
        //this.refreshData();
    }

    handleChangeAddressToSend(postCodActCPA, self){
		self.selectedaddress = postCodActCPA;
		super.fireEvent('selectedaddress',self.selectedaddress);
	}

    get mapMarkers(){                
        if(this.address != null && typeof(this.address) != 'undefined'){
            let addressObj = this.address;
            
            return [
                {
                    location: {
                        City: addressObj.city,
                        Country: addressObj.Country,
                        PostalCode: addressObj.postalCode,
                        State: addressObj.state,
                        Street: addressObj.street,
                    }                    
                }];
        }
    }

    renderedCallback(){//No entiendo bien
        const style = document.createElement('style');
        style.innerText = `.slds-map {
        max-height: 200px!important;min-width: auto;
        }
        .slds-map:before{padding-top:200px!important}`;
        if(this.template.querySelector('lightning-map') != null && typeof(this.template.querySelector('lightning-map')) != 'undefined'){
            this.template.querySelector('lightning-map').appendChild(style);
        }        
    }

    get sapIdCPAFormated(){
        return (this.sapIdCPA != null && this.sapIdCPA != 'undefined'?this.sapIdCPA:'-');
    }

}